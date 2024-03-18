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

(define-module (toys client)
  #:use-module (toys http)
  #:use-module (json)
  #:use-module (web client)
  #:use-module (web response)

  #:export (search-packages
            show-packages
            search-services
            show-services
            search-channels
            show-channels
            search-public-symbols
            show-public-symbols))

(define %default-instance-url "https://toys.whereis.xn--q9jyb4c")

(define (request method args)
  (let* ((uri (format #f "~a/api/~a?~a"
                      %default-instance-url method (build-query-string args)))
         (response (http-get uri #:decode-body? #f #:streaming? #t))
         (code (response-code response))
         (result (json->scm (response-body-port response #:keep-alive? #f))))
    (if (equal? code 200)
      (values result #f)
      (values #f (format #f "toys instance responded with ~d: ~a"
                         code
                         (scm->json-string result))))))

(define (search-packages query)
  (request "packages" `(("search" . ,query))))

(define (show-packages query)
  (request "packages" `(("show" . ,query))))

(define (search-services query)
  (request "services" `(("search" . ,query))))

(define (show-services query)
  (request "services" `(("show" . ,query))))

(define (search-channels query)
  (request "channels" `(("search" . ,query))))

(define (show-channels query)
  (request "channels" `(("show" . ,query))))

(define (search-public-symbols query)
  (request "symbols" `(("search" . ,query))))

(define (show-public-symbols query)
  (request "symbols" `(("show" . ,query))))
