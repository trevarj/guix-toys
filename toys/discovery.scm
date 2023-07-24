;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022, 2023 unwox <me@unwox.com>
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

(define-module (toys discovery)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix channels)
  #:use-module (guix discovery)
  #:use-module (guix describe)
  #:use-module (guix git)
  #:use-module (guix memoization)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (guix records)
  #:use-module (guix store)
  #:use-module (guix ui)
  #:use-module (guix utils)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-71)

  #:export (%current-channels
            fetch-boxes
            fold-public-symbols

            toys-box
            toys-box-channel
            toys-box-forge
            toys-box-directory))

;; Guix channel wrapper with additional data.
(define-record-type* <toys-box>
  toys-box make-toys-box
  toys-box?

  (channel toys-box-channel)        ; channel
  (forge toys-box-forge             ; string | #f
        (default #f))
  ;; directory in repository where source code for channel is situated
  ;; TODO: parse from .guix-channel file?
  (directory toys-box-directory     ; string | #f
             (default #f)))

(define %current-channels
  (string-append (getenv "HOME")
                 "/.config/guix/channels.scm"))

(define (fetch-boxes file)
  (define toy-boxes (primitive-load file))
  (map
    (lambda (box)
      (let*
        ((channel (toys-box-channel box))
         (url  (channel-url channel))
         (name (channel-name channel))
         (ref  (or (channel-commit channel)
                   (channel-branch channel)
                   "master")))
        (format #t "Fetching ~a...\n" url)
        `((box . ,box)
          (dir . ,(string-append
                    (update-cached-checkout
                      url
                      #:ref `(branch . ,ref)
                      #:recursive? #t)
                    "/"
                    (or (toys-box-directory box)
                        ""))))))
    toy-boxes))

(define (fold-public-symbols kons knil boxes)
  (define old-load-path %load-path)
  (set! %load-path
    (append
      (map
        (lambda (box-wrapper)
          (assoc-ref box-wrapper 'dir))
        ;; filter out guix
        (filter
          (lambda (box-wrapper)
            (not (equal? 'guix
                    (channel-name
                      (toys-box-channel (assoc-ref box-wrapper 'box))))))
          boxes))
      %load-path))

  (define public-symbols
    (fold
      (lambda (box-wrapper result)
        (format #t "Scanning ~a...\n"
                (symbol->string
                  (channel-name
                    (toys-box-channel (assoc-ref box-wrapper 'box)))))
        (let*
          ((box (assoc-ref box-wrapper 'box))
           (dir (assoc-ref box-wrapper 'dir))
           (modules (scheme-modules
                       dir
                       #:warn warn-about-load-error)))
          (append
            (fold-module-public-variables*
              (lambda (module symbol variable result)
                (apply kons
                       (list box module symbol variable result)))
              knil
              modules)
            result)))
      '()
      boxes))

  (set! %load-path old-load-path)
  public-symbols)
