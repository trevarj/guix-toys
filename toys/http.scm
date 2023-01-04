;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022 unwox <me@unwox.com>
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

(define-module (toys http)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (web uri)

  #:export (handle-not-found
            request-path-components
            request-query-parameters
            request-query-parameter))

(define (handle-not-found)
  "Returns the 404 response."
  (values (build-response #:code 404
                          #:headers
                          '((content-type . (application/json))))
          "{\"error\": \"not found\"}"))

(define (request-path-components request)
  "Returns REQUEST's URI splitted by \"/\".  Convenient for trivial routing."
  (split-and-decode-uri-path (uri-path (request-uri request))))

(define (request-query-parameters request)
  "(A naive implementation that) Returns an alist of query values from the
given REQUEST."
  (map (lambda (param)
         (let ((vals (string-split param #\=)))
           (cons (car vals) (cadr vals))))
       (string-split (uri-query (request-uri request))
                     #\&)))

(define (request-query-parameter request param)
  "Returns value of the given query PARAM.  If there is no such value,
returns #f."
  (assoc-ref (request-query-parameters request)
             param))
