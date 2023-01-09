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

(define %styles
  "
  html {
    line-height: 1.35;
    font-family: monospace, sans-serif;
  }

  .container {
    max-width: 48rem;
    margin: 1rem auto;
  }

  .muted {
    color: #444444;
  }


  .menu {
    color: #444444;
    display: flex;
    font-size: 0.75rem;
    margin-bottom: 0.5rem;
    text-transform: lowercase;
  }

  .menu a {
    color: blue;
  }

  .menu a.active {
    color: #444444;
    text-decoration: none;
  }

  .menu a + a {
    margin-left: 0.5rem;
  }

  .item {
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 0.125rem dashed #eeeeee;
  }

  pre {
    margin-bottom: 2rem;
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
  }
")

(define (base-template body current query)
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
                     (required "required")
                     (value ,(or query ""))
                     (placeholder "Enter query")))
           (button (@ (type "submit")) "Search"))
         (main ,@body)))))

(define (menu-template pages current)
  `(nav
     (@ (class "menu"))
      "'("
     ,@(map
         (lambda (item)
           `(a
              (@ (href ,(assoc-ref item 'href))
                 (class ,(if (equal? (assoc-ref item 'href)
                                     current)
                           "active"
                           "")))
              ,(assoc-ref item 'name)))
         pages)
    ")"))

(define (packages-template items query)
  (base-template
    (vector->list
      (vector-map
        (lambda (_ item) (package-template item))
        items))
    "/"
    query))

(define (services-template items query)
  (base-template
    (vector->list
      (vector-map
        (lambda (_ item) (service-template item))
        items))
    "/services"
    query))

(define (channels-template items query)
  (base-template
    (vector->list
      (vector-map
        (lambda (_ item) (channel-template item))
        items))
    "/channels"
    query))

(define (symbols-template items query)
  (base-template
    (vector->list
      (vector-map
        (lambda (_ item) (symbol-template item))
        items))
    "/symbols"
    query))

(define (package-template package)
  `(div (@ (class "item"))
     (strong
       ,(assoc-ref package "name")
       " "
       ,(assoc-ref package "version"))
     ,(if (> (vector-length (assoc-ref package "inputs")) 0)
        `(div
           (span (@ (class "muted")) "Dependencies: ")
           ,(inputs->links (assoc-ref package "inputs")))
        "")
     (div
       (span (@ (class "muted")) "Location: ")
       ,(assoc-ref package "location"))
     (div
       (span (@ (class "muted")) "Home page: ")
       (a
         (@ (href ,(assoc-ref package "homepage"))
            (rel "nofollow"))
         ,(assoc-ref package "homepage")))
     (div
       (span (@ (class "muted")) "License: ")
       ,(assoc-ref package "license"))
     (div
       (span (@ (class "muted")) "Channel: ")
       (a
         (@ (href ,(string-append "/channels?search="
                                  (assoc-ref package "channel"))))
         ,(assoc-ref package "channel")))
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
     (div
       (span (@ (class "muted")) "Location: ")
       ,(assoc-ref service "location"))
     (div
       (span (@ (class "muted")) "Channel: ")
       (a
         (@ (href ,(string-append "/channels?search="
                                  (assoc-ref service "channel"))))
         ,(assoc-ref service "channel")))
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
       ,(assoc-ref channel "branch"))
     (div
       (span (@ (class "muted")) "Commit: ")
       ,(assoc-ref channel "commit"))))

(define (symbol-template symbol)
  `(div (@ (class "item"))
     (strong ,(assoc-ref symbol "name"))
     (div
       (span (@ (class "muted")) "Module: ")
       "("
       ,(string-join
          (map
            (lambda (part) (symbol->string part))
            (module-name (assoc-ref symbol "module"))))
       ")")
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
  (vector->list
    (vector-map
      (lambda (_ input)
        `(span
           (a
             (@ (href ,(string-append "/?search="
                                      (car (string-split input #\@)))))
             ,input)
           " "))
      inputs)))
