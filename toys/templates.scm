;;; GNU Guix --- Functional package management for GNU
;;;
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

(define-module (toys templates)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-43)
  #:use-module (texinfo)
  #:use-module (ice-9 pretty-print)
  #:use-module (texinfo html)

  #:export (packages-template
            services-template
            symbols-template
            channels-template))

(define %pages
  '(((name . "Packages")
     (href . "/"))
    ((name . "Services")
     (href . "/services"))
    ((name . "Channels")
     (href . "/channels"))
    ((name . "Public symbols")
     (href . "/symbols"))
    ((name . "Source code")
     (href . "https://git.sr.ht/~whereiseveryone/toys"))
    ((name . "Issue tracker")
     (href . "https://todo.sr.ht/~whereiseveryone/toys"))))

(define %title
"       _            _    _        _         _
      /\\ \\         /\\ \\ /\\ \\     /\\_\\      / /\\
      \\_\\ \\       /  \\ \\\\ \\ \\   / / /     / /  \\
      /\\__ \\     / /\\ \\ \\\\ \\ \\_/ / /     / / /\\ \\__
     / /_ \\ \\   / / /\\ \\ \\\\ \\___/ /     / / /\\ \\___\\
    / / /\\ \\ \\ / / /  \\ \\_\\\\ \\ \\_/      \\ \\ \\ \\/___/
   / / /  \\/_// / /   / / / \\ \\ \\        \\ \\ \\
  / / /      / / /   / / /   \\ \\ \\   _    \\ \\ \\
 / / /      / / /___/ / /     \\ \\ \\ /_/\\__/ / /
/_/ /      / / /____\\/ /       \\ \\_\\\\ \\/___/ /
\\_\\/       \\/_________/         \\/_/ \\_____\\/
")

(define %empty-results-art
"                              _     _
                             ( \\---/ )
                              ) . . (
________________________,--._(___Y___)_,--._______________________ hjw
                        `--'           `--'
")

(define %styles
  "
  html {
    line-height: 1.45;
    font-family: monospace, sans-serif;
    font-size: 0.875rem;
  }

  .container {
    max-width: 48rem;
    margin: 1rem auto;
  }

  .muted {
    color: rgba(0, 0, 0, 0.5);
  }

  main {
    margin-top: 2rem;
  }

  .menu {
    color: #444444;
    display: flex;
    flex-wrap: wrap;
    margin-bottom: 0.375rem;
    text-transform: lowercase;
    margin-bottom: 0.75rem;
    gap: 0.375rem 0.75rem;
  }

  a {
    color: blue;
  }

  form {
    display: flex;
    gap: 0.5rem;
  }

  form input {
    max-width: 18.75rem;
    width: 100%;
  }

  .item {
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 0.0625rem solid #e0e0e0;
    word-break: break-word;
  }

  .item:last-child {
    border-bottom: 0;
  }

  header pre {
    margin-bottom: 2rem;
  }

  .code {
    background-color: rgba(0, 0, 0, 0.05);
    display: block;
    overflow-x: auto;
    padding: 0.5rem;
  }

  .item strong {
    display: block;
    margin-bottom: 0.25rem;
  }

  .item .description p:first-child {
    margin-top: 0;
  }

  .item .description p:last-child {
    margin-bottom: 0;
  }

  code {
    background-color: rgba(0, 0, 0, 0.05);
    padding: 0.25rem;
    white-space: nowrap;
  }

  .pre {
    background-color: rgba(0, 0, 0, 0.05);
    padding: 0.25rem;
    margin: 0;
  }

  .paginator {
    display: flex;
    flex-wrap: wrap;
    margin-bottom: 0.5rem;
    gap: 0.5rem;
  }

  .paginator-active {
    font-weight: bold;
    text-decoration: none;
    pointer-events: none;
  }

  @media (max-width: 32rem) {
    header pre {
      font-size: 0.75rem;
    }

    .not-found {
      display: none;
    }
  }

  @media (prefers-color-scheme: dark) {
    html {
      background: rgba(0, 0, 0, 0.9);
      color: white;
    }

    code,
    .code {
      background-color: rgba(255, 255, 255, 0.1);
    }

    .pre {
      background-color: rgba(255, 255, 255, 0.1);
    }

    a {
      color: #a2c6ff;
    }

    .muted {
      color: rgba(255, 255, 255, 0.5);
      text-decoration: none;
    }

    .item {
      border-bottom: 0.0625rem solid rgba(255, 255, 255, 0.1);
    }
  }
")

(define (base-template body current query page total channels channel)
  `(html
     (@ (lang "en"))
     (head
       (title "Toys / Webring for GNU Guix channels")
       (style ,%styles)
       (meta (@ (name "viewport")
                (content "width=device-width,initial-scale=1")))
       (meta (@ (name "charset")
                (content "utf8"))))
     (body
       (div
         (@ (class "container"))
         (header
           (pre ,%title)
           ,(menu-template %pages current))
         (form
           (input (@ (type "search")
                     (aria-label "Search")
                     (autofocus "autofocus")
                     (name "search")
                     (value ,(or query ""))
                     (placeholder "Enter query")))
          ,(if (< 0 (length channels))
            `(select (@ (name "channel"))
              (option (@ (value "")) "All channels")
              ,@(map
                  (lambda (item)
                   `(option ,(if (equal? item channel)
                              `(@ (value ,item)
                                  (selected "selected"))
                              `(@ (value ,item)))
                            ,item))
                  channels))
             "")
           (button (@ (type "submit")) "Search"))
         (main ,@body)))))

(define (menu-template pages current)
  `(nav
     (@ (class "menu"))
     ,@(map
         (lambda (item)
           `(a
              (@ (href ,(assoc-ref item 'href))
                 (class ,(if (equal? (assoc-ref item 'href)
                                     current)
                           "muted"
                           "")))
              ,(assoc-ref item 'name)))
         pages)))

(define (base-items-template path items query normalizer placeholder
                             page total channels channel request-params
                             api-surface)
  "Returns base template for search pages."
  (base-template
    `(,(if (and (or (not (string? query))
                    (string-null? query)))
         placeholder
         "")
      ,(if (and (string? query)
                (not (string-null? query))
                (= (length items) 0))
        `("Nothing found, try another query!"
          (div (@ (class "not-found"))
              (pre ,%empty-results-art)
              (small (@ (class "muted")) "Art by Hayley Jane Wakenshaw")))
        `(,(map (lambda (item) (normalizer item)) items)
          ,(paginator-template request-params page 24 total api-surface))))
    path query page total channels channel))

(define (placeholder-template method)
 `((p "Enter the query into the form above. "
      ,@(if (equal? method "/api/packages")
          '("You can look for specific version of a package by using "
            (code "@") " symbol like this: "
            (code "gcc@10") ".")
          '()))
   (p "API method:")
   (pre (@ (class "code"))
        "GET " ,method "?search=hello&page=1&limit=20")
   (p "where "
      (code "search")
      " is your query, "
      (code "page")
      " is a page number and "
      (code "limit")
      " is a number of items on a single page. "
      "Pagination information (such as a number of pages and etc) is returned
       in response headers. ")
   (p
     "If you'd like to join our channel search send a patch to "
     (a (@ (href "mailto:~whereiseveryone/toys@lists.sr.ht"))
        "~whereiseveryone/toys@lists.sr.ht")
     " adding your channel as an entry in "
     (a (@ (href "https://git.sr.ht/~whereiseveryone/toys/tree/master/item/channels.scm"))
        "channels.scm") ".")
   (hr (@ (style "margin: 2rem 0; opacity: 0.3;")))))

(define (packages-template items query page total channels channel request-params)
  (base-items-template "/" items query package-template
                       (placeholder-template "/api/packages")
                       page total channels channel request-params
                       "packages"))

(define (services-template items query page total channels channel request-params)
  (base-items-template "/services" items query service-template
                       (placeholder-template "/api/services")
                       page total channels channel request-params
                       "services"))

(define (channels-template items query page total request-params)
  (base-items-template "/channels" items query channel-template
                       (placeholder-template "/api/channels")
                       page total (list) #f request-params
                       "channels"))

(define (symbols-template items query page total channels channel request-params)
  (base-items-template "/symbols" items query symbol-template
                       (placeholder-template "/api/symbols")
                       page total channels channel request-params
                       "public symbols"))

(define (package-template package)
  `(div (@ (class "item"))
     (strong
       ,(assoc-ref package "name")
       " "
       ,(assoc-ref package "version"))
     ,(if (> (length (assoc-ref package "inputs")) 0)
        `(div
           (span (@ (class "muted")) "Dependencies: ")
           ,(symbol-inputs (assoc-ref package "inputs")))
        "")
     ,(if (> (length (assoc-ref package "propagated-inputs")) 0)
        `(div
           (span (@ (class "muted")) "Propagated dependencies: ")
           ,(symbol-inputs (assoc-ref package "propagated-inputs")))
        "")
     ,(symbol-channel (assoc-ref package "channel"))
     ,(symbol-link package)
     (div
       (span (@ (class "muted")) "Home page: ")
       (a
         (@ (href ,(assoc-ref package "homepage"))
            (rel "nofollow"))
         ,(assoc-ref package "homepage")))
     (div
       (span (@ (class "muted")) "Licenses: ")
       ,@(symbol-licenses (assoc-ref package "licenses")))
     (div
       (span (@ (class "muted")) "Build system: ")
       ,(assoc-ref package "build-system"))
     (div
       (span (@ (class "muted")) "Synopsis: ")
       ,(assoc-ref package "synopsis"))
     ,(if (assoc-ref package "description")
        `(div
          (span (@ (class "muted")) "Description: ")
          (div (@ (class "description"))
               ,(texi->html (assoc-ref package "description")))
        ""))))

(define (service-template service)
  `(div (@ (class "item"))
     (strong ,(assoc-ref service "name"))
     ,(symbol-channel (assoc-ref service "channel"))
     ,(symbol-link service)
     ,(if (assoc-ref service "description")
        `(div
          (span (@ (class "muted")) "Description: ")
          (div (@ (class "description"))
               ,(texi->html (assoc-ref service "description")))
        ""))))

(define (channel-template channel)
  `(div (@ (class "item"))
     (strong ,(assoc-ref channel "name"))
     (div
       (span (@ (class "muted")) "URL: ")
       (a
         (@ (href ,(assoc-ref channel "url"))
            (rel "nofollow"))
         ,(assoc-ref channel "url")))
     ,(if (not (string-null? (assoc-ref channel "synopsis")))
        `(div
          (span (@ (class "muted")) "Synopsis: ")
          ,(assoc-ref channel "synopsis"))
        "")
     (div
       (span (@ (class "muted")) "Branch: ")
       ,(assoc-ref channel "branch"))
     (div
       (span (@ (class "muted")) "Commit: ")
       ,(assoc-ref channel "commit"))
     (div
       (span (@ (class "muted")) "Packages: ")
       (a (@ (href ,(string-append "/?channel=" (assoc-ref channel "name"))))
        ,(assoc-ref channel "packages-count")))
     (div
       (span (@ (class "muted")) "Services: ")
       (a (@ (href ,(string-append "/services?channel="
                                   (assoc-ref channel "name"))))
        ,(assoc-ref channel "services-count")))
     (details
       (summary (@ (class "muted")) "Subscription snippet: ")
       (pre
        (@ (class "pre"))
        ,(assoc-ref channel "subscription-snippet")))))

(define (symbol-template symbol)
  `(div (@ (class "item"))
     (strong ,(if (> (string-length (assoc-ref symbol "signature")) 0)
                (assoc-ref symbol "signature")
                (assoc-ref symbol "name")))
     ,(symbol-channel (assoc-ref symbol "channel"))
     ,(symbol-link symbol)
     ,(if (and (assoc-ref symbol "doc")
               (> (string-length (assoc-ref symbol "doc"))
                  0))
        `(div
          (span (@ (class "muted")) "Documentation: ")
          (div (@ (class "description"))
               ,(texi->html (assoc-ref symbol "doc"))))
        "")))

(define (symbol-inputs inputs)
  (map
    (lambda (input)
      `(span
         (a (@ (href ,(string-append "/?show=" (car (string-split input #\@)))))
           ,input)
         " "))
    inputs))

(define (symbol-link symbol)
  (let ((url (assoc-ref symbol "url"))
        (file (assoc-ref symbol "file")))
    `(div
      (span (@ (class "muted")) "Location: ")
      (a (@ (href ,url)
            (rel "nofollow"))
         ,file)
      " "
      (code "(" ,(assoc-ref symbol "module") ")"))))

(define (symbol-channel channel)
  `(div
    (span (@ (class "muted")) "Channel: ")
    (a (@ (href ,(string-append "/channels?show=" channel))
          (rel "nofollow"))
       ,channel)))

(define (symbol-licenses licenses)
  (map
    (lambda (item)
      (let ((name (assoc-ref item "name"))
            (uri (assoc-ref item "uri")))
        `(,(if (and (not (string-null? uri))
                    (not (string-prefix? "file://" uri)))
             `(a (@ (href ,uri)) ,name)
             name)
          ;; warn if license is nonfree
          ,(if (equal? name "Nonfree")
            '(span (@ (style "color: red; font-weight: bold; margin-left: 0.25rem;"))
                    "⚠")
            "")
          " ")))
    licenses))

(define (texi->html texi)
  (if (> (string-length texi) 0)
    (or
      (false-if-exception
        (stexi->shtml
          (texi-fragment->stexi texi)))
      texi)
    ""))

(define (paginator-template query-params page limit total api-surface)
  (define last-page (ceiling (/ total limit)))

  (define query-string-without-page "")
  (for-each
    (lambda (v)
      (let ((key (car v))
            (value (cdr v)))
        (when (not (equal? key "page"))
          (set! query-string-without-page
            (string-append query-string-without-page "&" key "=" value)))))
    query-params)

  (define (page-link n)
    `(a (@ (href ,(string-append "?page=" (number->string n)
                                 query-string-without-page))
           (class ,(if (= page n) "paginator-active" "")))
      ,(number->string n)))

  (define (numbers-template current-page last-page)
    (let* ((window 2)
           (start (max 1 (- current-page window)))
           (end (min last-page (+ current-page window)))
           (ellipsis '(span (@ (class "paginator-ellipsis")) "…"))
           (head (cond
                   ((<= start 1) '())
                   ((= start 2) (list (page-link 1)))
                   (else (list (page-link 1) ellipsis))))
           (middle (if (<= start end)
                     (map page-link (iota (- end start -1) start))
                     '()))
           (tail (cond
                   ((>= end last-page) '())
                   ((= end (- last-page 1)) (list (page-link last-page)))
                   (else (list ellipsis (page-link last-page))))))
      (append head middle tail)))

  (list
    (if (< limit total)
      `(div (@ (class "paginator"))
            "Page: " ,(numbers-template page last-page))
      "")
    (if (< 0 total)
      `(div ,(string-append "Total " api-surface ": ")
            (strong ,(number->string total)))
      "")))
