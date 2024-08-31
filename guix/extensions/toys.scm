;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022 Charles Jackson <charles.b.jackson@protonmail.com>
;;; Copyright © 2022 jgart <jgart@dismail.de>
;;; Copyright © 2022-2024 unwox <me@unwox.com>
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
  #:use-module (toys client)
  #:use-module (toys cmd clone)
  #:use-module (toys cmd install)
  #:use-module (toys http)
  #:use-module (toys discovery)
  #:use-module (toys templates)
  #:use-module (toys ui)
  #:use-module (gnu services)
  #:use-module (guix channels)
  #:use-module (guix licenses)
  #:use-module (guix modules)
  #:use-module (guix packages)
  #:use-module (guix scripts)
  #:use-module (guix utils)
  #:use-module (guix ui)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (json)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-43)
  #:use-module (sxml simple)
  #:use-module (web request)
  #:use-module (web server)
  #:use-module (sqlite3)

  #:export (guix-toys))

(define (print-paginated-results method results)
  (with-paginated-output-port paginated
    (for-each
      (lambda (p)
        (method p paginated)
        (newline paginated))
      (vector->list results))))

(define-command (guix-toys . args)
  (category extension)
  (synopsis "Explore packages and services through REST API")
  (match args

    (("init")
     (init-db db))

    (("pull" file)
     (pull-data db (fetch-boxes file)))

    (("serve")
     (debug "Listening on :8080")
     (run-server toys-api))

    (("package" "search" query)
     (define-values (res err) (search-packages query))
     (when err (error err))
     (print-paginated-results print-package res))

    (("package" "show" query)
     (define-values (res err) (show-packages query))
     (when err (error err))
     (print-paginated-results print-package res))

    ((or ("package" "install" . packages)
         ("install" . packages))
     (if (< 0 (length packages))
      (for-each install-package packages)
      (show-help)))

    (("package" "clone" name . rest)
     (define packages (show-packages name))
     (when (< 0 (vector-length packages))
       (let* ((package (vector-ref packages 0))
              (origin (deserialize-origin (assoc-ref package "origin")))
              (directory (if (null? rest) name (car rest))))
         (clone-origin origin (or directory name)))))

    (("service" "search" query)
     (define-values (res err) (search-services query))
     (when err (error err))
     (print-paginated-results print-service res))

    (("service" "show" query)
     (define-values (res err) (show-services query))
     (when err (error err))
     (print-paginated-results print-service res))

    (("channel" "search" query)
     (define-values (res err) (search-channels query))
     (when err (error err))
     (print-paginated-results print-channel res))

    (("channel" "show" query)
     (define-values (res err) (show-channels query))
     (when err (error err))
     (print-paginated-results print-channel res))

    (("symbol" "search" query)
     (define-values (res err) (search-public-symbols query))
     (when err (error err))
     (print-paginated-results print-public-symbol res))

    (("symbol" "show" query)
     (define-values (res err) (show-public-symbols query))
     (when err (error err))
     (print-paginated-results print-public-symbol res))

    (_
      (show-help))))

(define (show-help)
  (display "Usage: guix toys [OPTION] ACTION [ARGS]
Perform the toys related actions. Before running \"serve\" make sure
the database was initialized and symbols were pulled.
The valid values for ACTION are:

   init
       initialize the database file
   pull FILE
       fetch symbols data from the channels defined in FILE
   serve
       start the web server listening on 127.0.0.1:8080

   channel search QUERY
       search for a channel in the toys instance database
   channel show NAME
       search for a channel with the exact NAME in the toys instance database

   package search QUERY
       search for a package in the toys instance database
   package show NAME
       search for a package with the exact NAME in the toys instance database
   package clone PACKAGE [DIR]
       clone a PACKAGE source code to current directory into a DIR
   package install PACKAGES
       install PACKAGES the toys instance knows about
   install PACKAGES
       an alias for \"package install PACKAGES\"

   service search QUERY
       search for a service type in the toys instance database
   service show NAME
       search for a service with the exact NAME in the toys instance database

   symbol search QUERY
       search for a public symbol in the toys instance database
   symbol show NAME
       search for a public symbol with the exact NAME in the toys instance
       database")
  (newline)
  (display "
  -h   display this help and exit")
  (newline)
  (exit 1))

(define (debug msg)
  "Prints the debug MSG to stdout."
  (display (string-append "% " msg "\n")))

(define %db-directory
  (string-append (cache-directory #:ensure? #t)
                 "/toys"))
(when (not (file-exists? %db-directory))
  (mkdir %db-directory))

(define db
  (sqlite-open
    (format #f "file:~a/db.sqlite"
            %db-directory)))

(define %last-updated-at
  (date->string (current-date 0) "~4"))

(define (db-execute-stmt stmt data)
 "Binds DATA to the STMT and then executes it."
 (apply sqlite-bind-arguments
        (cons stmt data))
 (sqlite-fold cons '() stmt))

(define (init-db db)
  "Initializes database schema."
  (sqlite-exec
    db
    "PRAGMA foreign_keys = ON;
     PRAGMA journal_mode=WAL;
     PRAGMA synchronous=NORMAL;

     DROP TABLE IF EXISTS search;
     CREATE VIRTUAL TABLE search USING fts5(name, description, fk, `table`);

     DROP TABLE IF EXISTS boxes;
     CREATE TABLE boxes (
       id TEXT NOT NULL PRIMARY KEY,
       dir TEXT NOT NULL,
       branch TEXT NOT NULL,
       `commit` TEXT,
       url TEXT NOT NULL,
       synopsis TEXT NOT NULL,
       subscription_snippet TEXT NOT NULL
     );
     DROP TABLE IF EXISTS public_symbols;
     CREATE TABLE public_symbols (
       id INTEGER NOT NULL PRIMARY KEY,
       name TEXT NOT NULL,
       channel INTEGER NOT NULL,
       module TEXT NOT NULL,
       file TEXT NOT NULL,
       url TEXT NOT NULL,
       doc TEXT,
       signature TEXT
     );
     DROP TABLE IF EXISTS service_types;
     CREATE TABLE service_types (
       id INTEGER NOT NULL PRIMARY KEY,
       name TEXT NOT NULL,
       channel INTEGER NOT NULL,
       module TEXT NOT NULL,
       file TEXT NOT NULL,
       url TEXT NOT NULL,
       description TEXT
     );
     DROP TABLE IF EXISTS packages;
     CREATE TABLE packages (
       id INTEGER NOT NULL PRIMARY KEY,
       name TEXT NOT NULL,
       channel INTEGER NOT NULL,
       module TEXT NOT NULL,
       file TEXT NOT NULL,
       url TEXT NOT NULL,
       version TEXT NOT NULL,
       homepage TEXT,
       licenses TEXT,
       synopsis TEXT,
       inputs TEXT,
       propagated_inputs TEXT,
       description TEXT,
       origin TEXT NOT NULL
     );

     CREATE INDEX packages_channels_idx ON packages (channel);
     CREATE INDEX services_channels_idx ON packages (channel);
    "))

(define (pull-data db boxes)
  "Removes existing data about symbols from DB and then pulls new data
from BOXES into it."
  (sqlite-exec
    db
    "PRAGMA synchronous=NORMAL;
     BEGIN IMMEDIATE;
     DELETE FROM search;
     DELETE FROM boxes;
     DELETE FROM public_symbols;
     DELETE FROM service_types;
     DELETE FROM packages;")

  (for-each
    (lambda (wrapper)
      (let* ((stmt
              (sqlite-prepare
                db
                "INSERT INTO boxes
                 (id, dir, branch, `commit`, url, synopsis, subscription_snippet)
                 VALUES (?, ?, ?, ?, ?, ?, ?)
                 RETURNING id"
                #:cache? #t))
            (search-stmt
              (sqlite-prepare
                db
                "INSERT INTO search
                 (name, description, fk, `table`)
                 VALUES (?, ?, ?, ?)"
                #:cache? #t))
            (dir (assoc-ref wrapper 'module-dir))
            (box (assoc-ref wrapper 'box))
            (channel (toys-box-channel box)))
        (define id
          (vector-ref
            (car
              (db-execute-stmt
                stmt
                (list
                  (symbol->string (channel-name channel))
                  dir
                  (channel-branch channel)
                  (assoc-ref wrapper 'commit)
                  (channel-url channel)
                  (toys-box-synopsis box)
                  (serialize-channel channel))))
            0))
        (db-execute-stmt
          search-stmt
          (list
            (symbol->string (channel-name channel))
            "" id "boxes"))))
    boxes)

  (fold-public-symbols
    (lambda (box module symbol variable box-wrapper result)
      (insert-public-symbol variable db module box symbol box-wrapper)

      (when (variable-bound? variable)
        (let ((var (variable-ref variable)))
          (cond
            ((service-type? var)
              (insert-service-type var db box module box-wrapper))
            ((package? var)
              (insert-package var db box module box-wrapper)))))

      '())
    '()
    boxes)
  (sqlite-exec db "COMMIT"))

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

;;;
;;; Locations
;;;

(define (location->url box-wrapper file lineno)
  "Returns the URL for accessing specified BOX, FILE and LINENO via Web."
  (let* ((box (assoc-ref box-wrapper 'box))
         (directory (string-trim
                      (assoc-ref box-wrapper 'dir)
                      #\/))
         (channel (toys-box-channel box))
         (file (string-trim-both
                 (format #f "~a/~a"
                         directory file)
                 #\/))
         (ref (or (channel-commit channel)
                  (channel-branch channel)
                  "master"))
         (forge (and channel
                     (toys-box-forge box)))
         (base-url (if (equal? (channel-name channel)
                               'guix)
                     "https://git.savannah.gnu.org/cgit/guix.git"
                     (and channel
                          (channel-url channel)))))
    (if (and base-url forge)
      (cond
        ((equal? forge "cgit")
         (format #f "~a/tree/~a?id=~a#n~d"
                 base-url file ref lineno))
        ((equal? forge "sourcehut")
         (format #f "~a/tree/~a/item/~a#L~d"
                 base-url ref file lineno))
        ((equal? forge "gitlab")
         (format #f "~a/-/blob/~a/~a#L~d"
                 base-url ref file lineno))
        ((equal? forge "github")
         (format #f "~a/blob/~a/~a#L~d"
                 base-url ref file lineno))
        ((equal? forge "gitea")
         (format #f "~a/src/commit/~a/~a#L~d"
                 base-url ref file lineno))
        ((equal? forge "gogs")
         (format #f "~a/src/~a/~a#L~d"
                 base-url ref file lineno))
        ((equal? forge "codeberg")
         (format #f "~a/src/branch/~a/~a#L~d"
                 base-url ref file lineno))
        (else #f))
      #f)))

(define (serialize-channel channel)
  "Formats CHANNEL for database storage."
  (let ((channel-sexp (channel->code channel)))
    (call-with-output-string
      (lambda (port)
        (pretty-print channel-sexp port)))))

(define (serialize-license license)
  "Formats LICENSE for database storage."
  (let ((normalize (lambda (item)
                     (format #f "[~a](~a)"
                             (license-name item)
                             (license-uri item)))))
    (if (list? license)
      (map normalize
           license)
      (if license
        (list (normalize license))
        '()))))

(define (serialize-public-symbol variable module box symbol box-wrapper)
  "Serializes VARIABLE for database storage."
  (let* ((variable-procedure?
           (and (variable-bound? variable)
                (procedure? (variable-ref variable))))
         (mod-name
           (string-join
             (map
               symbol->string
               (module-name module))
             " "))
         (name
           (symbol->string symbol))
         (channel-name
           (symbol->string (channel-name (toys-box-channel box))))
         (file
           (module-name->file-name (module-name module)))
         (url
           ;; TODO: figure out if it's possible to extract lineno from variable.
           ;; For now set it to 1.
           (location->url box-wrapper file 1))
         (signature
           (or (and
                 variable-procedure?
                 (procedure-name (variable-ref variable))
                 (format #f "~a" (variable-ref variable)))
               ""))
         (stripped-signature
           (if (> (string-length signature) 0)
             (string-drop  ; drop "#<procedure "
               (string-drop-right  ; drop ">"
                 signature
                 1)
               12)
             ""))
         (doc
           (or (and
                 variable-procedure?
                 (procedure-documentation (variable-ref variable)))
               "")))
    (list name
          channel-name
          mod-name
          file
          url
          doc
          stripped-signature)))

(define (insert-public-symbol variable db module box symbol box-wrapper)
  "Serializes and inserts VARIABLE and corresponding search row into the DB."
  (let* ((stmt
           (sqlite-prepare
             db
             "INSERT INTO public_symbols
              (name, channel, module, file, url, doc, signature)
              VALUES (?,?,?,?,?,?,?)
              RETURNING id"
             #:cache? #t))
         (search-stmt
           (sqlite-prepare
             db
             "INSERT INTO search
              (name, description, fk, `table`)
              VALUES (?,?,?,?)"
             #:cache? #t))
         (data
           (serialize-public-symbol variable module box symbol box-wrapper)))
    (define id
      (vector-ref
        (car (db-execute-stmt stmt data))
        0))
    (db-execute-stmt
      search-stmt
      (list (symbol->string symbol) "" id "public_symbols"))))

(define (serialize-service-type service-type box module box-wrapper)
  "Serializes SERVICE-TYPE for database storage."
  (let* ((mod-name
           (string-join
             (map
               symbol->string
               (module-name module))
             " "))
         (name
           (symbol->string (service-type-name service-type)))
         (channel-name
           (symbol->string (channel-name (toys-box-channel box))))
         (file
           (module-name->file-name (module-name module)))
         (location
           (service-type-location service-type))
         (url
           (location->url box-wrapper file (location-line location)))
         (description
           (service-type-description service-type)))
    (list name
          channel-name
          mod-name
          file
          url
          description)))

(define (insert-service-type service-type db box module box-wrapper)
  "Serializes and inserts SERVICE-TYPE and corresponding search row
into the DB."
  (let* ((stmt
           (sqlite-prepare
             db
             "INSERT INTO service_types
              (name, channel, module, file, url, description)
              VALUES (?,?,?,?,?,?)
              RETURNING id"
             #:cache? #t))
         (search-stmt
           (sqlite-prepare
             db
             "INSERT INTO search
              (name, description, fk, `table`)
              VALUES (?,?,?,?)"
             #:cache? #t))
         (data
           (serialize-service-type service-type box module box-wrapper)))
    (define id
      (vector-ref
        (car (db-execute-stmt stmt data))
        0))
    (db-execute-stmt
      search-stmt
      (list (symbol->string (service-type-name service-type))
            (service-type-description service-type)
            id
            "service_types"))))

(define (serialize-package package box module box-wrapper)
  "Serializes PACKAGE for database storage."
  (let* ((name (package-name package))
         (version (package-version package))
         (channel-name (symbol->string (channel-name (toys-box-channel box))))
         (mod-name
           (string-join
             (map
               symbol->string
               (module-name module))
             " "))
         (file (module-name->file-name (module-name module)))
         (location (package-location package))
         (url (location->url box-wrapper file (location-line location)))
         (homepage
           (package-home-page package))
         (licenses
           (string-join
             (serialize-license (package-license package))
             "|"))
         (synopsis (package-synopsis package))
         (inputs
           (or (false-if-exception
                 (string-join
                   (normalize-inputs
                     (package-inputs package))
                   "|"))
               ""))
         (propagated-inputs
           (or (false-if-exception
                 (string-join
                   (normalize-inputs
                     (package-propagated-inputs package))
                   "|"))
               ""))
         (description (package-description package))
         (origin (if (and (package-source package)
                          (origin? (package-source package)))
                   (or
                    (false-if-exception
                      (scm->json-string
                       (serialize-origin (package-source package))))
                    "")
                   "")))
    (list name
          channel-name
          mod-name
          file
          url
          version
          homepage
          licenses
          synopsis
          inputs
          propagated-inputs
          description
          origin)))

(define (insert-package package db box module box-wrapper)
  "Serializes and inserts PACKAGE and corresponding search row into the DB."
  (let* ((stmt
           (sqlite-prepare
             db
             "INSERT INTO packages
              (name,
               channel,
               module,
               file,
               url,
               version,
               homepage,
               licenses,
               synopsis,
               inputs,
               propagated_inputs,
               description,
               origin)
              VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
              RETURNING id"
             #:cache? #t))
         (search-stmt
           (sqlite-prepare
             db
             "INSERT INTO search
              (name, description, fk, `table`)
              VALUES (?,?,?,?)"
             #:cache? #t))
         (data
           (serialize-package package box module box-wrapper)))
    (define id
      (vector-ref
        (car (db-execute-stmt stmt data))
        0))
    (db-execute-stmt
      search-stmt
      (list (package-name package)
            (package-description package)
            id
            "packages"))))

(define (gather-row row columns)
  "Constructs an associated list with named items from ROW that sqlite3
returned."
  (vector-fold
    (lambda (k result col)
      (cons `(,col . ,(vector-ref row k))
            result))
    '()
    columns))

(define (all-symbols select from)
  "Queries SELECT fields from all symbols in the FROM table.  Use `j.` prefix
for selecting fields."
  (let*
    ((stmt
       (sqlite-prepare
         db
         (format #f "SELECT ~a FROM ~a j" select from)))
     (columns
       (sqlite-column-names stmt)))
    (sqlite-map
      (lambda (row)
        (gather-row row columns))
      stmt)))

(define (show-symbols select from name)
  "Queries SELECT fields from the FROM table with records *exactly* matching
NAME string.  Use `j.` prefix for selecting fields."
  (let*
    ((stmt
       (sqlite-prepare
         db
         ;; unfortunately we have to work around the fact that the boxes table
         ;; structure is quite different from other tables: it doesn't have
         ;; a name and a channel fields
         (if (equal? from "boxes")
          (format #f "SELECT ~a FROM boxes j WHERE j.id = ?" select)
          (format #f "SELECT ~a FROM ~a j WHERE j.name = ? ORDER BY j.channel"
                  select from))))
     (columns (sqlite-column-names stmt)))
    (sqlite-bind-arguments stmt name)
    (sqlite-map
      (lambda (row)
        (gather-row row columns))
      stmt)))

(define (search-symbols select from query)
  "Queries SELECT fields from the FROM table with records matching QUERY
string.  Use `j.` prefix for selecting fields."
  (let*
    ((stmt
       (sqlite-prepare
         db
         (format #f
                 "SELECT ~a FROM search s
                  INNER JOIN ~a j ON s.fk = j.id
                  WHERE s.`table` = ?
                  AND s.name MATCH ?
                  ORDER BY LENGTH(s.name), rank"
                  select
                  from)))
     (columns
       (sqlite-column-names stmt))
     (wildcard
       (format #f "\"~a\" *"
               (string-delete #\" query))))
    (sqlite-bind-arguments stmt from wildcard)
    (sqlite-map
      (lambda (row)
        (gather-row row columns))
      stmt)))

(define (denormalize-api-rows rows)
  "Denormalizes ROWS received from the database.  Explodes strings back to
lists and etc."
  (let*
    ((denormalize-pair
       (lambda (key value)
         (cond
           ((equal? key "origin")
            `(,key . ,(if (not (string-null? value))
                        (json-string->scm value)
                        #f)))
           (else `(,key . ,value)))))
     (denormalize-row
       (lambda (row)
         (map
           (lambda (pair)
             (denormalize-pair (car pair) (cdr pair)))
           row))))
    (map denormalize-row rows)))

(define (denormalize-rows rows)
  "Denormalizes ROWS received from the database.  Explodes strings back to
lists and etc."
  (let*
    ((split
       (lambda (str)
         (if (not (string-null? str))
           (string-split str #\|)
           '())))
     (denormalize-license
       (lambda (value)
         `(("name" . ,(match:substring
                        (string-match "\\[(.*)\\]" value)
                        1))
           ("uri"  . ,(match:substring
                        (string-match "\\((.*)\\)" value)
                        1)))))
     (denormalize-pair
       (lambda (key value)
         (cond
           ((or (equal? key "inputs")
                (equal? key "propagated-inputs")
                (equal? key "propagatedInputs"))
            `(,key . ,(split value)))
           ((or (equal? key "licenses"))
            `(,key . ,(map denormalize-license
                           (split value))))
           (else `(,key . ,value)))))
     (denormalize-row
       (lambda (row)
         (map
           (lambda (pair)
             (denormalize-pair (car pair) (cdr pair)))
           row))))
    (map denormalize-row rows)))

;;;
;;; API
;;;

(define (handle-api-search request select from)
  "Handles generic API request for RECORDS with pagination and search
functionality."
  (let* ((search-query (request-query-parameter request "search"))
         (show-query (request-query-parameter request "show"))
         (searcher (if show-query show-symbols search-symbols))
         (query (or show-query search-query)))
    (values `((content-type . (application/json)))
            (scm->json-string
              (list->vector
                (denormalize-api-rows
                  (if query
                    (searcher select from query)
                    (all-symbols select from))))))))

(define (handle-api-packages-search request)
  "Returns the list of packagess whose name contains a value from \"search\"
query parameter."
  (handle-api-search request
                     "j.name,
                      j.channel,
                      j.module,
                      j.file,
                      j.url,
                      j.version,
                      j.homepage,
                      j.licenses,
                      j.synopsis,
                      j.inputs,
                      j.propagated_inputs AS propagatedInputs,
                      j.origin,
                      j.description"
                     "packages"))

(define (handle-api-services-search request)
  "Returns the list of services whose name contains a value from \"search\"
query parameter."
  (handle-api-search request
                     "j.name,
                      j.channel,
                      j.module,
                      j.file,
                      j.url,
                      j.description"
                     "service_types"))

(define (handle-api-channels-list request)
  "Returns the list of channels defined in channels.scm."
  (handle-api-search request
                     "j.id AS name,
                      j.branch,
                      j.`commit`,
                      j.url,
                      (SELECT COUNT(*) FROM packages AS p WHERE p.channel = j.id) AS `packagesCount`,
                      (SELECT COUNT(*) FROM service_types AS s WHERE s.channel = j.id) AS `servicesCount`,
                      j.subscription_snippet AS `subscriptionSnippet`"
                      "boxes"))

(define (handle-api-symbols-list request)
  "Returns the list of all public (exported) symbols defined in
%package-module-path."
  (handle-api-search request
                     "j.name,
                      j.channel,
                      j.module,
                      j.file,
                      j.url,
                      j.doc,
                      j.signature"
                     "public_symbols"))

;;;
;;; HTML pages
;;;

(define (handle-search-page request select from template)
  "Handles generic search page request for RECORDS using TEMPLATE."
  (let* ((search-query (request-query-parameter request "search"))
         ;; when search query is wrapped into double quotes (e.g. "emacs")
         ;; consider it a show query instead requiring exact match
         (quoted-search-query
           (string-match "\"([^\"']+)\""
                         (string-trim-both (or search-query ""))))
         (show-query
           (if quoted-search-query
            search-query
            (request-query-parameter request "show")))
         (searcher (if show-query show-symbols search-symbols))
         (query (or show-query search-query)))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (template
                  (if query
                    (denormalize-rows
                      (searcher select from (string-trim-both query #\")))
                    '())
                  query
                  %last-updated-at)
                port)))))

(define (handle-index-page request)
  "Returns the index page."
  (handle-search-page request
                      "j.name,
                       j.channel,
                       j.module,
                       j.file,
                       j.url,
                       j.version,
                       j.homepage,
                       j.licenses,
                       j.synopsis,
                       j.inputs,
                       j.propagated_inputs as `propagated-inputs`,
                       j.description"
                      "packages"
                      packages-template))

(define (handle-services-page request)
  "Returns the services search page."
  (handle-search-page request
                      "j.name,
                       j.channel,
                       j.module,
                       j.file,
                       j.url,
                       j.description"
                      "service_types"
                      services-template))

(define (handle-channels-page request)
  "Returns the channels search page."
  (let ((query (request-query-parameter request "search"))
        (fields
          "j.id AS name,
           j.branch,
           j.`commit`,
           (SELECT COUNT(*) FROM packages AS p WHERE p.channel = j.id) AS `packages-count`,
           (SELECT COUNT(*) FROM service_types AS s WHERE s.channel = j.id) AS `services-count`,
           j.url,
           j.synopsis,
           j.subscription_snippet AS `subscription-snippet`"))
    (values '((content-type . (text/html)))
            (lambda (port)
              (sxml->xml
                (channels-template
                  (if query
                    (search-symbols fields "boxes" query)
                    (all-symbols fields "boxes"))
                  query
                  %last-updated-at)
                port)))))

(define (handle-symbols-page request)
  "Returns the symbols search page."
  (handle-search-page request
                      "j.name,
                       j.channel,
                       j.module,
                       j.file,
                       j.url,
                       j.doc,
                       j.signature"
                      "public_symbols"
                      symbols-template))

(define (toys-api request request-body)
  "Routes and handles incoming HTTP requests."
  (match (request-path-components request)
    (("api" "packages")
     (handle-api-packages-search request))
    (("api" "services")
     (handle-api-services-search request))
    (("api" "channels")
     (handle-api-channels-list request))
    (("api" "symbols")
     (handle-api-symbols-list request))
    (()
     (handle-index-page request))
    (("services")
     (handle-services-page request))
    (("channels")
     (handle-channels-page request))
    (("symbols")
     (handle-symbols-page request))
    (_ (handle-not-found))))
