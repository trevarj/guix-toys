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
  #:use-module (guix colors)
  #:use-module (guix ui)

  #:export (print-package
            print-service
            print-channel
            print-public-symbol))

(define* (definition title definition port #:key (bold? #f))
  (when (and definition
             (not (string-null? definition)))
    (display title port)
    (display ": " port)
    (if bold?
      (display
        (colorize-string definition (color BOLD))
        port)
      (display definition port))
    (newline port)))

(define (print-package package port)
  (definition "name" (assoc-ref package "name") port #:bold? #t)
  (definition "version" (assoc-ref package "version") port #:bold? #t)
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
  (definition "name" (assoc-ref service "name") port #:bold? #t)
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

(define (print-channel channel port)
  (definition "name" (assoc-ref channel "name") port #:bold? #t)
  (definition "url" (assoc-ref channel "url") port)
  (definition "branch" (assoc-ref channel "branch") port)
  (definition "packages count"
    (number->string
     (assoc-ref channel "packages_count")) port)
  (definition "services count"
    (number->string
     (assoc-ref channel "services_count")) port)
  (definition "subscription snippet"
    (string-append
     "\n"
     (assoc-ref channel "subscription_snippet")) port))

(define (print-public-symbol symbol port)
  (definition
    "name"
    (if (not (string-null? (assoc-ref symbol "signature")))
      (assoc-ref symbol "signature")
      (assoc-ref symbol "name"))
    port
    #:bold? #t)
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
