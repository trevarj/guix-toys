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
  #:use-module (json)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (web uri)

  #:export (handle-not-found
            request-path-components
            request-query-parameters
            request-query-parameter
            paginated-response))

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
  (let ((query (uri-query (request-uri request))))
    (if query
      (filter (negate null?)
              (map (lambda (param)
                     (let ((vals (string-split param #\=)))
                       (cons
                         (uri-decode (car vals))
                         (uri-decode (cadr vals)))))
                   (string-split query #\&)))
      '())))

(define (request-query-parameter request param)
  "Returns value of the given query PARAM.  If there is no such value,
returns #f."
  (assoc-ref (request-query-parameters request)
             param))

(define (paginated-response request items)
  "Returns paginated response for the given REQUEST with ITEMS vector splitted
(according to \"page\" and \"limit\" query parameters) and encoded to JSON."
  (let* ((total (vector-length items))
         (limit (min 1000 (or (string->number
                                (or (request-query-parameter request "limit")
                                    ""))
                              100)))
         (pages (max 1 (ceiling (/ total limit))))
         (page (min pages
                    (or (string->number
                          (or (request-query-parameter request "page")
                              ""))
                        1)))
         (start (* (- page 1) limit))
         (end (max start
                   (min (+ start limit) total)))
         (result (vector-copy items start end)))
    (values `((content-type . (application/json))
              (paginator-page . ,(number->string page))
              (paginator-limit . ,(number->string limit))
              (paginator-pages . ,(number->string pages))
              (paginator-total . ,(number->string total)))
            (scm->json-string result))))
