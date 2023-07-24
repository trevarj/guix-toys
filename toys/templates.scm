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
    color: #444444;
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
    background-color: #efefef;
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
    background-color: #efefef;
    padding: 0.25rem;
    white-space: nowrap;
  }

  footer {
    font-style: italic;
    color: gray;
    margin-top: 1rem;
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
      background: #222222;
      color: white;
    }

    code,
    .code {
      background-color: #444444;
    }

    a {
      color: #a2c6ff;
    }

    .muted {
      color: #999999;
      text-decoration: none;
    }

    .item {
      border-bottom: 0.0625rem solid #444444;
    }
  }
")

(define (base-template body current query last-updated-at)
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
         (main ,@body)
         (footer
           "Last updated at: "
           ,last-updated-at)))))

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

(define (base-items-template path items query normalizer placeholder last-updated-at)
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
          (map
            (lambda (item)
              (normalizer item))
            items)))
      path
      query
      last-updated-at))

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

(define (packages-template items query last-updated-at)
  (base-items-template "/"
                       items
                       query
                       package-template
                       (placeholder-template "/api/packages")
                       last-updated-at))

(define (services-template items query last-updated-at)
  (base-items-template "/services"
                       items
                       query
                       service-template
                       (placeholder-template "/api/services")
                       last-updated-at))

(define (channels-template items query last-updated-at)
  (base-items-template "/channels"
                       items
                       query
                       channel-template
                       (placeholder-template "/api/channels")
                       last-updated-at))

(define (symbols-template items query last-updated-at)
  (base-items-template "/symbols"
                       items
                       query
                       symbol-template
                       (placeholder-template "/api/symbols")
                       last-updated-at))

(define (package-template package)
  `(div (@ (class "item"))
     (strong
       ,(assoc-ref package "name")
       " "
       ,(assoc-ref package "version"))
     ,(if (equal? (assoc-ref package "channel")
                  "guix")
        `(div
           (span (@ (class "muted")) "Repology: ")
           "provided: "
           ,(repology-badge package)
           ", latest known "
           ,(repology-latest-badge package))
        "")
     ,(if (> (length (assoc-ref package "inputs")) 0)
        `(div
           (span (@ (class "muted")) "Dependencies: ")
           ,(inputs->links (assoc-ref package "inputs")))
        "")
     ,(if (> (length (assoc-ref package "propagated-inputs")) 0)
        `(div
           (span (@ (class "muted")) "Propagated dependencies: ")
           ,(inputs->links (assoc-ref package "propagated-inputs")))
        "")
     ,(channel->html (assoc-ref package "channel"))
     ,(symbol-link package)
     (div
       (span (@ (class "muted")) "Home page: ")
       (a
         (@ (href ,(assoc-ref package "homepage"))
            (rel "nofollow"))
         ,(assoc-ref package "homepage")))
     (div
       (span (@ (class "muted")) "Licenses: ")
       ,@(license->sxml (assoc-ref package "licenses")))
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
     ,(channel->html (assoc-ref service "channel"))
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
     (div
       (span (@ (class "muted")) "Branch: ")
       ,(assoc-ref channel "branch"))))
     ; (div
     ;   (span (@ (class "muted")) "Commit: ")
     ;   ,(assoc-ref channel "commit"))))
     ; (div
     ;   (span (@ (class "muted")) "Packages: ")
     ;   ,(assoc-ref (assoc-ref channel "stats")
     ;               "packages"))
     ; (div
     ;   (span (@ (class "muted")) "Services: ")
     ;   ,(assoc-ref (assoc-ref channel "stats")
     ;               "services"))))

(define (symbol-template symbol)
  `(div (@ (class "item"))
     (strong ,(if (> (string-length (assoc-ref symbol "signature")) 0)
                (assoc-ref symbol "signature")
                (assoc-ref symbol "name")))
     ,(channel->html (assoc-ref symbol "channel"))
     ,(symbol-link symbol)
     ,(if (and (assoc-ref symbol "doc")
               (> (string-length (assoc-ref symbol "doc"))
                  0))
        `(div
          (span (@ (class "muted")) "Documentation: ")
          (div (@ (class "description"))
               ,(texi->html (assoc-ref symbol "doc"))))
        "")))

(define (texi->html texi)
  (if (> (string-length texi) 0)
    (or
      (false-if-exception
        (stexi->shtml
          (texi-fragment->stexi texi)))
      texi)
    ""))

(define (inputs->links inputs)
  (map
    (lambda (input)
      `(span
         (a
           (@ (href ,(string-append "/?search="
                                    (car (string-split input #\@)))))
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

(define (channel->html channel)
  `(div
    (span (@ (class "muted")) "Channel: ")
    (a
      (@ (href ,(string-append "/channels?search="
                                channel))
          (rel "nofollow"))
      ,channel)))

(define (license->sxml license)
  (map
    (lambda (item)
      `((a (@ (href ,(assoc-ref item "uri")))
           ,(assoc-ref item "name"))
        ;; warn if license is nonfree
        ,(if (equal? (assoc-ref item "name") "Nonfree")
           '(span (@ (style "color: red; font-weight: bold; margin-left: 0.25rem;"))
                  "⚠")
           '())
        " "))
    license))

(define (repology-badge package)
  (let ((name (assoc-ref package "name")))
    `((a (@ (href ,(string-append "https://repology.org/project/"
                                  name
                                  "/versions#gnuguix"))
            (style "vertical-align: bottom;"))
         (img (@ (src ,(string-append "https://repology.org/badge/version-for-repo/gnuguix/"
                                      name
                                      ".svg?header="))
                 (alt ,(string-append name " version"))))))))

(define (repology-latest-badge package)
  (let ((name (assoc-ref package "name"))
        (version (assoc-ref package "version")))
    `((a (@ (href ,(string-append "https://repology.org/project/"
                                  name
                                  "/versions#gnuguix"))
            (style "vertical-align: bottom;"))
         (img (@ (src ,(string-append "https://repology.org/badge/latest-versions/"
                                      name
                                      ".svg?header=&minversion="
                                      version))
                 (alt ,(string-append "Latest packaged version:" version))))))))
