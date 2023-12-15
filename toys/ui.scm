;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2023 unwox <me@unwox.com>
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

(define-module (toys ui)
  #:use-module (guix ui)

  #:export (print-package
            print-service
            print-public-symbol))

(define (definition title definition port)
  (when (and definition
             (not (string-null? definition)))
    (display title port)
    (display ": " port)
    (display definition port)
    (newline port)))

(define (print-package package port)
  (definition "name" (assoc-ref package "name") port)
  (definition "version" (assoc-ref package "version") port)
  (definition "channel" (assoc-ref package "channel") port)
  (definition
    "inputs"
    (string-join (string-split (assoc-ref package "inputs") #\|)
                 " ")
    port)
  (definition "propagated inputs" (assoc-ref package "propagatedInputs") port)
  (definition
    "location"
    (string-append (assoc-ref package "file")
                   " (" (assoc-ref package "module") ")")
    port)
  (definition "definition url" (assoc-ref package "url") port)
  (definition "homepage" (assoc-ref package "homepage") port)
  (definition "licenses" (assoc-ref package "licenses") port)
  (definition "synopsis" (assoc-ref package "synopsis") port)
  (definition
    "description"
    (string-trim-both
      (texi->plain-text (assoc-ref package "description"))
      #\newline)
    port))

(define (print-service service port)
  (definition "name" (assoc-ref service "name") port)
  (definition "channel" (assoc-ref service "channel") port)
  (definition
    "location"
    (string-append (assoc-ref service "file")
                   " (" (assoc-ref service "module") ")")
    port)
  (definition "definition url" (assoc-ref service "url") port)
  (definition
    "description"
    (string-trim-both
      (texi->plain-text (assoc-ref service "description"))
      #\newline)
    port))

(define (print-public-symbol symbol port)
  (definition
    "name"
    (if (not (string-null? (assoc-ref symbol "signature")))
      (assoc-ref symbol "signature")
      (assoc-ref symbol "name"))
    port)
  (definition "channel" (assoc-ref symbol "channel") port)
  (definition
    "location"
    (string-append (assoc-ref symbol "file")
                   " (" (assoc-ref symbol "module") ")")
    port)
  (definition "definition url" (assoc-ref symbol "url") port)
  (definition
    "documentation"
    (string-trim-both
      (texi->plain-text (assoc-ref symbol "documentation"))
      #\newline)
    port))
