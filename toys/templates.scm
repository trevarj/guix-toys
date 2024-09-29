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
     (href . "https://git.sr.ht/~whereiseveryone/toys"))))

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

  button {
    margin-left: 0.25rem;
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

(define (base-template body current query page total)
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

(define (base-items-template path items query normalizer placeholder page total)
  "Returns base template for search pages."
  (base-template
    (if (and (or (not (string? query))
                 (= (string-length query) 0))
             (= (length items) 0))
      placeholder
      (if (and (string? query)
              (> (string-length query) 0)
              (= (length items) 0))
        `("Nothing found, try another query!"
          (div (@ (class "not-found"))
              (pre ,%empty-results-art)
              (small (@ (class "muted"))
                      "Art by Hayley Jane Wakenshaw")))
        `(,(map
            (lambda (item)
              (normalizer item))
            items)
          ,(paginator-template query page 24 total))))
    path
    query
    page
    total))

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
   "If you'd like to join our channel webring send a patch to "
   (a (@ (href "mailto:~whereiseveryone/toys@lists.sr.ht"))
      "~whereiseveryone/toys@lists.sr.ht")
   " adding your channel as an entry in "
   (a (@ (href "https://git.sr.ht/~whereiseveryone/toys/tree/master/item/channels.scm"))
      "channels.scm") "."))

(define (packages-template items query page total)
  (base-items-template "/"
                       items
                       query
                       package-template
                       (placeholder-template "/api/packages")
                       page
                       total))

(define (services-template items query page total)
  (base-items-template "/services"
                       items
                       query
                       service-template
                       (placeholder-template "/api/services")
                       page
                       total))

(define (channels-template items query page total)
  (base-items-template "/channels"
                       items
                       query
                       channel-template
                       (placeholder-template "/api/channels")
                       page
                       total))

(define (symbols-template items query page total)
  (base-items-template "/symbols"
                       items
                       query
                       symbol-template
                       (placeholder-template "/api/symbols")
                       page
                       total))

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
       ,(assoc-ref channel "packages-count"))
     (div
       (span (@ (class "muted")) "Services: ")
       ,(assoc-ref channel "services-count"))
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
    (a (@ (href ,(string-append "/channels?search="
                                channel))
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

(define (paginator-template query page limit total)
  (define last-page (ceiling (/ total limit)))
  (define (numbers-template query current-page last-page)
   (fold-right
    (lambda (i result)
     (cons
      `(a (@ (href ,(string-append "?page=" (number->string (+ 1 i))
                                   "&search=" query))
             (class ,(if (= page (+ 1 i)) "paginator-active" "")))
        ,(number->string (+ 1 i)))
      result))
    '()
    (iota last-page)))

  (list
    (if (< limit total)
      `(div (@ (class "paginator"))
            "Page: " ,(numbers-template query page last-page))
      "")
    (if (< 0 total)
      `(div "Total results: " (strong ,(number->string total)))
      "")))
