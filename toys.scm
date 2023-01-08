#!/usr/bin/env sh
exec guile -L . -e '(@@ (toys) main)' -s "$0" "$@"
!#
;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022 Charles Jackson <charles.b.jackson@protonmail.com>
;;; Copyright © 2022 jgart <jgart@dismail.de>
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

(define-module (toys)
  #:use-module (toys http)
  #:use-module (toys discovery)
  #:use-module (gnu services)
  #:use-module (gnu services)
  #:use-module (guix channels)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix ui)
  #:use-module (guix utils)
  #:use-module (ice-9 match)
  #:use-module (json)
  #:use-module (web request)
  #:use-module (web server))

(define (debug msg)
  "Prints the debug MSG to stdout."
  (display (string-append "% " msg "\n")))

(define (license->string license)
  (if (list? license)
    (string-join
      (map (lambda (item)
             (license-name item))
           license)
      ", ")
    (if (eq? license #f)
      ""
      (license-name license))))

(define (channels->string channels)
  (if (null? channels)
    "guix"
    (string-join
      (map (lambda (channel)
             (symbol->string (channel-name channel)))
           channels)
      ", ")))

(define (package->alist package)
  "Returns the view of the PACKAGE normalized for API response."
  (let ((name (package-name package))
        (version (package-version package))
        (location (location->string (package-location package)))
        (channel (channels->string
                   (location-channels
                     (package-location package))))
        (homepage (package-home-page package))
        (license (license->string (package-license package)))
        (synopsis (package-synopsis package))
        (description (package-description package)))
    `(("name" . ,name)
      ("version" . ,version)
      ("location" . ,location)
      ("channel" . ,channel)
      ("homepage" . ,homepage)
      ("license" . ,license)
      ("synopsis" . ,synopsis)
      ("description" . ,description))))

(define (service-type->alist service-type)
  "Returns the view of the SERVICE-TYPE normalized for API response."
  (let ((name (symbol->string (service-type-name service-type)))
        (location (location->string (service-type-location service-type)))
        (channel (channels->string
                   (location-channels
                     (service-type-location service-type))))
        (description (service-type-description service-type)))
    `(("name" . ,name)
      ("location" . ,location)
      ("channel" . ,channel)
      ("description" . ,description))))

;; Storage for all packages extracted from %package-module-path.
(debug "Loading packages...")
(define %all-packages
  (map
    (lambda (item) (package->alist item))
    (all-packages)))

;; Storage for all service types extracted from %package-module-path.
(debug "Loading service types...")
(define %all-service-types
  (map
    (lambda (item) (service-type->alist item))
    (all-service-types)))

(define (handle-package-search request request-body)
  "Returns the list of packages whose name contains a value from \"search\"
query parameter."
  (let ((query (request-query-parameter request "search")))
    (if query
      (values '((content-type . (application/json)))
              (scm->json-string
                (apply vector
                       (find-records-by-name query
                                             %all-packages))))
      (handle-not-found))))

(define (handle-service-search request request-body)
  "Returns the list of services whose name contains a value from \"search\"
query parameter."
  (let ((query (request-query-parameter request "search")))
    (if query
      (values '((content-type . (application/json)))
              (scm->json-string
                (apply vector
                      (find-records-by-name query
                                            %all-service-types))))
      (handle-not-found))))

(define (toys-api request request-body)
  "Routes and handles incoming HTTP requests."
  (match (request-path-components request)
         ((? equal? '("packages"))
          (handle-package-search request request-body))
         ((? equal? '("services"))
          (handle-service-search request request-body))
         (_ (handle-not-found))))

(define (score-record record query)
  "Returns the (RECORD . score) pair where score is relevancy of the \"name\"
field to QUERY."
  (let ((name (assoc-ref record "name")))
    (match (string-contains-ci name query)
           ((? eq? #f)
            '())
           (offset
             (cons record
                   (+ offset (string-length name)))))))

(define (find-records-by-name query records)
  "Returns the subset of RECORDS filtered and sorted by the relevance to
QUERY."
  (map (lambda (record) (car record))
    (let ((matches (filter (negate null?)
                          (map (lambda (record)
                                  (score-record record
                                                query))
                                records))))
    (sort matches
          (lambda (m1 m2)
            (match m1
                  ((record1 . score1)
                    (match m2
                          ((record2 . score2)
                            (let ((name1 (assoc-ref record1 "name"))
                                  (name2 (assoc-ref record2 "name"))
                                  (version1 (assoc-ref record1 "version"))
                                  (version2 (assoc-ref record2 "version")))
                              (if (= score1 score2)
                                (if (string=? name1
                                              name2)
                                  (and version1
                                       version2
                                       (version>? version1
                                                  version2))
                                  (string>? name1
                                            name2))
                                (< score1 score2))))))))))))

;; Run toys JSON API.
(define (main args)
  (debug "Listening on :8080")
  (run-server toys-api))
