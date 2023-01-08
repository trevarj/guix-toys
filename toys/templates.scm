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

(define-module (toys templates)
  #:use-module (srfi srfi-43)

  #:export (index-template))

(define (index-template items)
  `(html
     (head
       (title "Toys / Webring for GNU Guix channels"))
     (body
       (h1 "Toys")
       (form
         (input (@ (type "search")
                   (name "search")
                   (required "required")
                   (placeholder "Enter query")))
         (button (@ (type "submit")) "Search"))
       ,@(vector->list
           (vector-map
             (lambda (_ item) (package-template item))
             items)))))

(define (package-template package)
  `(div (@ (style "margin-bottom: 1rem;"))
     (strong ,(assoc-ref package "name"))
     (div
       (span (@ (style "color: #555555;")) "Version: ")
       ,(assoc-ref package "version"))
     (div
       (span (@ (style "color: #555555;")) "Location: ")
       ,(assoc-ref package "location"))
     (div
       (span (@ (style "color: #555555;")) "Home page: ")
       ,(assoc-ref package "homepage"))
     (div
       (span (@ (style "color: #555555;")) "License: ")
       ,(assoc-ref package "license"))
     (div
       (span (@ (style "color: #555555;")) "Channel: ")
       ,(assoc-ref package "channel"))
     (div
       (span (@ (style "color: #555555;")) "Synopsis: ")
       ,(assoc-ref package "synopsis"))
     (div
       (span (@ (style "color: #555555;")) "Description: ")
       (div ,(assoc-ref package "description")))))
