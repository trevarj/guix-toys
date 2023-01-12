#!/usr/bin/env sh
exec guile -L . -e 'main' -s "$0" "$@"
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

(use-modules (toys http)
             (toys discovery)
             (toys templates)

             (gnu services)
             (gnu services)
             (guix channels)
             (guix licenses)
             (guix packages)
             (guix ui)
             (guix utils)
             (ice-9 match)
             (json)
             (srfi srfi-1)
             (srfi srfi-43)
             (sxml simple)
             (web request)
             (web server))

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

(define (channel->alist channel commit)
  "Returns the view of the CHANNEL normalized for API response. Accepts both
native guix channels and toys wrapper with additional data."
  (let* ((chan (if (channel? channel)
                 channel
                 (assoc-ref channel 'channel)))
         (name (symbol->string (channel-name chan)))
         (url (channel-url chan))
         (forge (or (assoc-ref channel 'forge)
                    ""))
         (branch (channel-branch chan)))
    `(("name" . ,name)
      ("url" . ,url)
      ("branch" . ,branch)
      ("forge" . ,forge)
      ("commit" . ,commit))))

(define (channel-record-by-name name)
  "Returns a channel with specified NAME from %all-channels.  If none found,
returns #f."
  (find
    (lambda (item)
      (string=? (assoc-ref item "name")
                name))
    (vector->list %all-channels)))

(define (location->url location channel-name)
  "Returns the URL for accessing specified LOCATION from channel with
CHANNEL-NAME via Web."
  (let* ((channel (channel-record-by-name channel-name))
         (file (location-file location))
         (line (location-line location))
         ; Extract ref from "commit" field and reference it in resulting URL
         (ref (or (assoc-ref channel "commit")
                  (assoc-ref channel "branch")
                  "master"))
         (forge (and channel
                     (assoc-ref channel "forge")))
         (base-url (if (equal? channel-name "guix")
                     "https://git.savannah.gnu.org/cgit/guix.git"
                     (and channel
                        (assoc-ref channel "url")))))
    (if (and base-url
             forge)
      (cond
        ((equal? forge "cgit")
         (format #f
                 "~a/tree/~a?id=~a#n~d"
                 base-url
                 file
                 ref
                 line))
        ((equal? forge "sourcehut")
         (format #f
                 "~a/tree/~a/item/~a#L~d"
                 base-url
                 ref
                 file
                 line))
        ((equal? forge "gitlab")
         (format #f
                 "~a/-/blob/~a/~a#L~d"
                 base-url
                 ref
                 file
                 line))
        ((equal? forge "github")
         (format #f
                 "~a/blob/~a/~a#L~d"
                 ref
                 base-url
                 file
                 line))
        (else #f))
      #f)))

(define (location->alist location)
  (let* ((channels (location-channels location))
         (file (location-file location))
         ; (module (string-append "("
         ;                        (string-join 
         ;                          (string-split file #\/)
         ;                          " ")
         ;                        ")"))
         (channel (channels->string channels))
         (url (location->url location channel)))
    `(("channel" . ,channel)
      ; ("module"  . ,module)
      ("file"    . ,file)
      ("url"     . ,url))))

(define (normalize-inputs inputs)
  (let ((input-packages (filter
                          (lambda (p)
                            (package? (cadr p)))
                          inputs)))
    (map
      (lambda (input)
        (define input-package (cadr input))
        (string-append
          (package-name input-package)
          "@"
          (package-version input-package)))
      input-packages)))

(define (package->alist package)
  "Returns the view of the PACKAGE normalized for API response."
  (let ((name (package-name package))
        (version (package-version package))
        (location (location->alist (package-location package)))
        (homepage (package-home-page package))
        (license (license->string (package-license package)))
        (synopsis (package-synopsis package))
        (inputs (or (false-if-exception
                      (apply vector
                             (normalize-inputs
                               (package-inputs package))))
                    #()))
        (description (package-description package)))
    `(("name" . ,name)
      ("version" . ,version)
      ("location" . ,location)
      ("homepage" . ,homepage)
      ("license" . ,license)
      ("synopsis" . ,synopsis)
      ("inputs" . ,inputs)
      ("description" . ,description))))

(define (service-type->alist service-type)
  "Returns the view of the SERVICE-TYPE normalized for API response."
  (let ((name (symbol->string (service-type-name service-type)))
        (location (location->alist
                    (service-type-location service-type)))
        (description (service-type-description service-type)))
    `(("name" . ,name)
      ("location" . ,location)
      ("description" . ,description))))

(debug "Loading channels...")
;; Storage for all channels extracted from channels.scm.
(define %all-channels
  (let* ((_ (load %current-channels))
         (guix-channels (all-channels))
         (toys-channels (and (defined? 'toys-channels)
                             toys-channels))
         (channels (or toys-channels
                       guix-channels
                       '()))
         (channel-name* (lambda (channel)
                          (channel-name
                            (if (channel? channel)
                              channel
                              ;; our custom wrapper with additional data
                              (assoc-ref channel 'channel)))))
         (find-commit (lambda (name)
                        (channel-commit
                          (find
                            (lambda (item)
                              (equal? (channel-name item)
                                      name))
                            guix-channels)))))
    (apply vector
           (map
             (lambda (item)
               (channel->alist item
                               ;; extract channel commit data from current profile
                               (find-commit
                                 (channel-name* item))))
             channels))))

;; Storage for all packages extracted from %package-module-path.
(debug "Loading packages...")
(define %all-packages
  (apply vector
         (map
           (lambda (item) (package->alist item))
           (sort (all-packages)
                 (lambda (a b)
                   (string<? (package-name a)
                             (package-name b)))))))

;; Storage for all service types extracted from %package-module-path.
(debug "Loading service types...")
(define %all-service-types
  (apply vector
    (map
      (lambda (item) (service-type->alist item))
      (sort (all-service-types)
            (lambda (a b)
              (string<? (symbol->string (service-type-name a))
                        (symbol->string (service-type-name b))))))))

;; Storage for all service types extracted from %package-module-path.
(debug "Loading public symbols...")
(define %all-public-symbols
  (apply vector
    (sort (all-public-symbols)
      (lambda (a b)
        (string<? (assoc-ref a "name"))
                  (assoc-ref b "name")))))

(define (handle-packages-search request request-body)
  "Returns the list of packagess whose name contains a value from \"search\"
query parameter."
  (let ((query (request-query-parameter request
                                        "search")))
    (paginated-response request
                        (if query
                          (find-records-by-name query %all-packages)
                          %all-packages))))

(define (handle-services-search request request-body)
  "Returns the list of services whose name contains a value from \"search\"
query parameter."
  (let ((query (request-query-parameter request
                                        "search")))
    (paginated-response request
                        (if query
                          (find-records-by-name query %all-service-types)
                          %all-service-types))))

(define (handle-channels-list request request-body)
  "Returns the list of channels defined in channels.scm."
  (values '((content-type . (application/json)))
          (scm->json-string %all-channels)))

(define (handle-symbols-list request request-body)
  "Returns the list of all public (exported) symbols defined in
%package-module-path."
  (let ((query (request-query-parameter request
                                        "search")))
    (paginated-response
      request
      ;; XXX: Additional processing since we do not store normalized view
      ;; in %all-public-symbols.
      (vector-map
        (lambda (_ symbol)
          `(("name" . ,(assoc-ref symbol "name"))
            ("module" . ,(string-join
                           (map
                             (lambda (part) (symbol->string part))
                             (module-name (assoc-ref symbol "module")))))
            ("doc" . ,(assoc-ref symbol "doc"))))
        (if query
          (find-records-by-name query %all-public-symbols)
          %all-public-symbols)))))

(define (handle-index-page request request-body)
  "Returns the index page."
  (let ((query (request-query-parameter request
                                        "search")))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (packages-template
                  (if query
                    (find-records-by-name query
                                          %all-packages)
                    #())
                  query)
                port)))))

(define (handle-services-page request request-body)
  "Returns the services search page."
  (let ((query (request-query-parameter request
                                        "search")))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (services-template
                  (if query
                    (find-records-by-name query
                                          %all-service-types)
                    #())
                  query)
                port)))))

(define (handle-channels-page request request-body)
  "Returns the channels search page."
  (let ((query (request-query-parameter request
                                        "search")))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (channels-template
                  (if query
                    (find-records-by-name query
                                          %all-channels)
                    %all-channels)
                  query)
                port)))))

(define (handle-symbols-page request request-body)
  "Returns the symbols search page."
  (let ((query (request-query-parameter request
                                        "search")))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (symbols-template
                  (if query
                    (find-records-by-name query
                                          %all-public-symbols)
                    #())
                  query)
                port)))))

(define (toys-api request request-body)
  "Routes and handles incoming HTTP requests."
  (match (request-path-components request)
         ((? equal? '("api" "packages"))
          (handle-packages-search request request-body))
         ((? equal? '("api" "services"))
          (handle-services-search request request-body))
         ((? equal? '("api" "channels"))
          (handle-channels-list request request-body))
         ((? equal? '("api" "symbols"))
          (handle-symbols-list request request-body))
         ((? equal? '())
          (handle-index-page request request-body))
         ((? equal? '("services"))
          (handle-services-page request request-body))
         ((? equal? '("channels"))
          (handle-channels-page request request-body))
         ((? equal? '("symbols"))
          (handle-symbols-page request request-body))
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
  "Returns the subset of RECORDS vector filtered and sorted by the relevance to
QUERY."
  (apply vector
    (map (lambda (record) (car record))
         (let ((matches (filter (negate null?)
                                (vector->list
                                  (vector-map (lambda (_ record)
                                                (score-record record
                                                              query))
                                              records)))))
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
                                       (< score1 score2)))))))))))))

;; Run toys JSON API.
(define (main args)
  (debug "Listening on :8080")
  (run-server toys-api))
