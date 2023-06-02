;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022 Charles Jackson <charles.b.jackson@protonmail.com>
;;; Copyright © 2022 jgart <jgart@dismail.de>
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

(define-module (guix extensions toys)
  #:use-module (toys http)
  #:use-module (toys discovery)
  #:use-module (toys templates)
  #:use-module (gnu services)
  #:use-module (guix channels)
  #:use-module (guix diagnostics)
  #:use-module (guix licenses)
  #:use-module (guix modules)
  #:use-module (guix packages)
  #:use-module (guix records)
  #:use-module (guix scripts)
  #:use-module (guix ui)
  #:use-module (guix utils)
  #:use-module (ice-9 match)
  #:use-module (json)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-43)
  #:use-module (sxml simple)
  #:use-module (web request)
  #:use-module (web server)

  #:export (guix-toys))

(define-command (guix-toys . args)
  (category extension)
  (synopsis "Explore packages and services through REST API")

  ;; Run toys JSON API.
  (debug "Listening on :8080")
  (run-server toys-api))

(define %last-updated-at
  (date->string (current-date 0) "~4"))

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

(define (debug msg)
  "Prints the debug MSG to stdout."
  (display (string-append "% " msg "\n")))

(define (license->list license)
  (let ((normalize (lambda (item)
                     `(("name" . ,(license-name item))
                       ("uri" . ,(license-uri item))))))
    (if (list? license)
      (map normalize
           license)
      (if license
        (list (normalize license))
        '()))))

;;;
;;; Channels
;;;

(define (count-packages channel)
  (length
    (filter
      (lambda (package)
        (equal?
          (channels->string
            (location-channels (package-location package)))
          (symbol->string (channel-name channel))))
      (all-packages))))

(define (count-services channel)
  (length
    (filter
      (lambda (service)
        (equal?
          (channels->string
            (location-channels (service-type-location service)))
          (symbol->string (channel-name channel))))
      (all-service-types))))

(define (channels->string channels)
  "Returns names for the given CHANNELS delimited by comma."
  (if (null? channels)
    "guix"
    (string-join
      (map (lambda (channel)
             (symbol->string (channel-name channel)))
           channels)
      ", ")))

(define (toys-box->alist toys-box commit)
  "Returns the view of the CHANNEL normalized for API response. Accepts both
native guix channels and toys wrapper with additional data."
  (let* ((channel (toys-box-channel toys-box))
         (name (symbol->string (channel-name channel)))
         (url (channel-url channel))
         (branch (channel-branch channel))
         (forge (or (toys-box-forge toys-box)
                    ""))
         (packages-count (count-packages channel))
         (services-count (count-services channel))
         (directory (or (toys-box-directory toys-box)
                        "")))
    `(("name" . ,name)
      ("url" . ,url)
      ("branch" . ,branch)
      ("forge" . ,forge)
      ("directory" . ,directory)
      ("stats" . (("packages" . ,packages-count)
                  ("services" . ,services-count)))
      ("commit" . ,commit))))

(define (channel-record-by-name name)
  "Returns a channel with specified NAME from %all-channels.  If none found,
returns #f."
  (find
    (lambda (item)
      (string=? (assoc-ref item "name")
                name))
    (vector->list %all-channels)))

(debug "Loading channels...")
;; Storage for all channels extracted from channels.scm.
(define %all-channels
  (let* ((_ (load %current-channels))
         (guix-channels (map
                          (lambda (channel)
                            (toys-box
                              (channel channel)))
                          (all-channels)))
         (toys-channels (and (defined? 'toys-boxes)
                             toys-boxes))
         (channels (or toys-channels
                       guix-channels
                       '()))
         (toys-box-name (lambda (channel)
                          (channel-name
                            (toys-box-channel channel))))
         (find-commit (lambda (name)
                        (channel-commit
                          ;; TODO: check for #f
                          (toys-box-channel
                            (find
                              (lambda (item)
                                (equal? (toys-box-name item)
                                        name))
                              guix-channels))))))
    (apply vector
           (map
             (lambda (item)
               (toys-box->alist item
                                ;; Extract channel commit data from current profile.
                                (find-commit
                                  (toys-box-name item))))
             channels))))

;;;
;;; Locations
;;;

(define (location->url location channel)
  "Returns the URL for accessing specified LOCATION from CHANNEL record via
Web."
  (let* ((directory (string-trim
                      (or (assoc-ref channel "directory")
                          "")
                      #\/))
         (line (location-line location))
         (file (string-trim
                 (string-append directory
                                "/"
                                (location-file location))
                 #\/))
         (ref (or (assoc-ref channel "commit")
                  (assoc-ref channel "branch")
                  "master"))
         (forge (and channel
                     (assoc-ref channel "forge")))
         (base-url (if (equal? (assoc-ref channel "name")
                               "guix")
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
                 base-url
                 ref
                 file
                 line))
        ((equal? forge "gitea")
         (format #f
                 "~a/src/commit/~a/~a#L~d"
                 base-url
                 ref
                 file
                 line))
        (else #f))
      #f)))

(define (location->alist location)
  "Returns normalized view of the LOCATION."
  (let* ((channels (location-channels location))
         (file (location-file location))
         (module (string-append "("
                                (string-join
                                  (string-split
                                    ;; drop .scm suffix
                                    (string-drop-right file
                                                       4) #\/)
                                  " ")
                                ")"))
         (channel (channels->string channels))
         (url (location->url location
                             (channel-record-by-name channel))))
    `(("channel" . ,channel)
      ("module"  . ,module)
      ("file"    . ,file)
      ("url"     . ,url))))

;;;
;;; Packages
;;;

(define (normalize-inputs inputs)
  "Returns normalized view of the INPUTS with their versions."
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
        (license (list->vector
                   (license->list (package-license package))))
        (synopsis (package-synopsis package))
        (inputs (or (false-if-exception
                      (apply vector
                             (normalize-inputs
                               (package-inputs package))))
                    #()))
        (propagated-inputs (or (false-if-exception
                                 (apply vector
                                        (normalize-inputs
                                          (package-propagated-inputs package))))
                               #()))
        (description (package-description package)))
    `(("name" . ,name)
      ("version" . ,version)
      ("location" . ,location)
      ("homepage" . ,homepage)
      ("license" . ,license)
      ("synopsis" . ,synopsis)
      ("inputs" . ,inputs)
      ("propagatedInputs" . ,propagated-inputs)
      ("description" . ,description))))

;; Storage for all packages extracted from %package-module-path.
(debug "Loading packages...")
(define %all-packages
  (apply vector
         (map
           package->alist
           (sort (all-packages)
                 (lambda (a b)
                   (string<? (package-name a)
                             (package-name b)))))))

;;;
;;; Services
;;;

(define (service-type->alist service-type)
  "Returns the view of the SERVICE-TYPE normalized for API response."
  (let ((name (symbol->string (service-type-name service-type)))
        (location (location->alist
                    (service-type-location service-type)))
        (description (service-type-description service-type)))
    `(("name" . ,name)
      ("location" . ,location)
      ("description" . ,description))))

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

;;;
;;; Public symbols
;;;

;; Storage for all service types extracted from %package-module-path.
(debug "Loading public symbols...")
(define %all-public-symbols
  (apply vector
    (map
      (lambda (symbol)
        (let* ((variable (assoc-ref symbol "variable"))
               (variable-procedure? (and (variable-bound? variable)
                                         (procedure? (variable-ref variable))))
               ;; TODO: figure out if it's possible to extract lineno and
               ;; column from variable. For now set both to 1
               (location (location
                           (module-name->file-name
                             (module-name (assoc-ref symbol "module")))
                           1
                           1))
               (signature (or (and
                                variable-procedure?
                                (procedure-name (variable-ref variable))
                                (format #f "~a" (variable-ref variable)))
                              ""))
               (stripped-signature (if (> (string-length signature) 0)
                                     (string-drop  ; drop "#<procedure "
                                       (string-drop-right  ; drop ">"
                                         signature
                                         1)
                                       12)
                                     ""))
               (doc (or (and
                          variable-procedure?
                          (procedure-documentation (variable-ref variable)))
                        "")))
          `(("name" . ,(symbol->string (assoc-ref symbol "name")))
            ("location" . ,(location->alist location))
            ("doc" . ,doc)
            ("signature" . ,stripped-signature))))
      (sort (all-public-symbols)
        (lambda (a b)
          (string<? (assoc-ref a "name"))
                    (assoc-ref b "name"))))))

;;;
;;; Records
;;;

(define (score-record record query)
  "Returns the (RECORD . score) pair where score is relevancy of the \"name\"
field to QUERY."
  (let* ((version (assoc-ref record "version"))
         (name (if version
                 (string-append (assoc-ref record "name")
                                "@"
                                version)
                 (assoc-ref record "name")))
         (tokens (string-split query #\space))
         (append-score (lambda (pair carry)
                         (if (null? carry)
                           pair
                           (cons (car carry)
                                 (+ (cdr pair)
                                    (cdr carry)))))))
    (fold
      (lambda (token carry)
        (if (eq? carry 'stop)
          'stop
          (match (string-contains-ci name token)
                 ((? eq? #f)
                  'stop)
                 (offset
                   (append-score
                     (cons record
                           offset)
                     carry)))))
      '()
      tokens)))

(define (find-records-by-name query records)
  "Returns the subset of RECORDS vector filtered and sorted by the relevance to
QUERY."
  (apply vector
    (map (lambda (record) (car record))
         (let ((matches (filter pair?
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
                                   (let* ((name1 (assoc-ref record1 "name"))
                                          (name2 (assoc-ref record2 "name"))
                                          (len1 (string-length name1))
                                          (len2 (string-length name2))
                                          (version1 (assoc-ref record1 "version"))
                                          (version2 (assoc-ref record2 "version")))
                                     (if (= score1 score2)
                                       (if (and (string=? name1 name2)
                                                version1
                                                version2)
                                         (version>? version1
                                                    version2)
                                         (and (string<? name1 name2)
                                              (< len1 len2)))
                                       (< score1 score2)))))))))))))

;;;
;;; API
;;;

(define (handle-api-search request request-body records)
  "Handles generic API request for RECORDS with pagination and search
functionality."
  (let ((query (request-query-parameter request
                                        "search")))
    (paginated-response request
                        (if query
                          (find-records-by-name query records)
                          records))))

(define (handle-api-packages-search request request-body)
  "Returns the list of packagess whose name contains a value from \"search\"
query parameter."
  (handle-api-search request
                     request-body
                     %all-packages))

(define (handle-api-services-search request request-body)
  "Returns the list of services whose name contains a value from \"search\"
query parameter."
  (handle-api-search request
                     request-body
                     %all-service-types))

(define (handle-api-channels-list request request-body)
  "Returns the list of channels defined in channels.scm."
  (handle-api-search request
                     request-body
                     %all-channels))

(define (handle-api-symbols-list request request-body)
  "Returns the list of all public (exported) symbols defined in
%package-module-path."
  (handle-api-search request
                     request-body
                     %all-public-symbols))

;;;
;;; HTML pages
;;;

(define (handle-search-page request request-body records template)
  "Handles generic search page request for RECORDS using TEMPLATE."
  (let ((query (string-trim-both
                 (or (request-query-parameter request "search")
                     ""))))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (template
                  (if (not (zero? (string-length query)))
                    (find-records-by-name query
                                          records)
                    #())
                  query
                  %last-updated-at)
                port)))))

(define (handle-index-page request request-body)
  "Returns the index page."
  (handle-search-page request
                      request-body
                      %all-packages
                      packages-template))

(define (handle-services-page request request-body)
  "Returns the services search page."
  (handle-search-page request
                      request-body
                      %all-service-types
                      services-template))

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
                  query
                  %last-updated-at)
                port)))))

(define (handle-symbols-page request request-body)
  "Returns the symbols search page."
  (handle-search-page request
                      request-body
                      %all-public-symbols
                      symbols-template))

(define (toys-api request request-body)
  "Routes and handles incoming HTTP requests."
  (match (request-path-components request)
         ((? equal? '("api" "packages"))
          (handle-api-packages-search request request-body))
         ((? equal? '("api" "services"))
          (handle-api-services-search request request-body))
         ((? equal? '("api" "channels"))
          (handle-api-channels-list request request-body))
         ((? equal? '("api" "symbols"))
          (handle-api-symbols-list request request-body))
         ((? equal? '())
          (handle-index-page request request-body))
         ((? equal? '("services"))
          (handle-services-page request request-body))
         ((? equal? '("channels"))
          (handle-channels-page request request-body))
         ((? equal? '("symbols"))
          (handle-symbols-page request request-body))
         (_ (handle-not-found))))
