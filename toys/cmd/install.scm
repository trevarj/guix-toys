;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2024 unwox <me@unwox.com>
;;;
;;; This file is not part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (toys cmd install)
  #:use-module (guix build utils)
  #:use-module (guix channels)
  #:use-module (guix colors)
  #:use-module (ice-9 eval-string)
  #:use-module (ice-9 readline)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-43)
  #:use-module (toys client)
  #:use-module (toys discovery)
  #:use-module (toys ui)

  #:export (install-package))

(define (install-package package-name)
  (let ((packages (show-packages package-name)))
    (when (< 0 (vector-length packages))
      (let* ((package (if (equal? 1 (vector-length packages))
                       (vector-ref packages 0)
                       (choose-package packages)))
             (channel-name (assoc-ref package "channel"))
             (channel (vector-ref (show-channels channel-name) 0))
             (channel-snippet (assoc-ref channel "subscriptionSnippet"))
             (evaluated-channel
               (eval-string channel-snippet
                            #:module (resolve-module '(guix channels))))
             (url (channel-url evaluated-channel))
             (ref (channel-branch evaluated-channel))
             (introduction (channel-introduction evaluated-channel))
             (checkout-dir (fetch-channel url ref introduction)))
        (invoke "guix" "install" "-L" checkout-dir package-name)))))

(define (choose-package packages)
  (vector-for-each
    (lambda (idx package)
      (display (colorize-string
                 (format #f "~a) " (+ idx 1))
                 (color RED BOLD)))
      (print-package package (current-output-port))
      (newline))
    packages)

  (let ((response (string->number (readline  "Choose the package: "))))
    (cond
      ((equal? response #f)
        (error "not a number"))
      ((or (< (- response 1) 0)
           (< (vector-length packages) (- response 1)))
        (error "incorrect number"))
      (else (vector-ref packages (- response 1))))))
