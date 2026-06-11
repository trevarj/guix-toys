;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022-2025 unwox <me@unwox.com>
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

(define-module (toys discovery)
  #:use-module (git)
  #:use-module (guix channels)
  #:use-module (guix discovery)
  #:use-module (guix describe)
  #:use-module (guix git)
  #:use-module (guix git-authenticate)
  #:use-module (guix ui)
  #:use-module (guix records)
  #:use-module (srfi srfi-1)

  #:export (fetch-boxes
            fetch-channel
            for-each-box
            for-each-symbol

            toys-box
            toys-box-channel
            toys-box-forge
            toys-box-synopsis))

;; Guix channel wrapper with additional data.
(define-record-type* <toys-box>
  toys-box make-toys-box
  toys-box?

  (channel toys-box-channel)        ; channel
  (forge toys-box-forge             ; string | #f
        (default #f))
  (synopsis toys-box-synopsis       ; string
            (default "")))

;; Forcefully export functions from (guix channels)
(define read-channel-metadata-from-source
  (@@ (guix channels) read-channel-metadata-from-source))

(define channel-metadata-directory
  (@@ (guix channels) channel-metadata-directory))

(define channel-metadata-dependencies
  (@@ (guix channels) channel-metadata-dependencies))

(define* (fetch-channel url ref #:optional (introduction #f))
  (format #t "Fetching ~a...\n" url)
  ;; Channel definitions go stale: a pinned branch may no longer exist
  ;; (e.g. renamed default branches). Fall back to the remote HEAD rather
  ;; than losing the channel entirely.
  (define checkout-dir
    (with-exception-handler
      (lambda (exception)
        (format (current-error-port)
          "guix toys: warning: ref ~s not found in ~a, trying default branch\n"
          ref url)
        (update-cached-checkout url))
      (lambda () (update-cached-checkout url #:ref `(branch . ,ref)))
      #:unwind? #t))
  (when introduction
   (format #t "Authenticating ~a...\n" url)
   (with-repository checkout-dir repository
                    (authenticate-repository
                      repository
                      (string->oid
                        (channel-introduction-first-signed-commit introduction))
                      (channel-introduction-first-commit-signer introduction)
                      ;; FIXME: may not be "keyring" branch.
                      #:keyring-reference "origin/keyring")))

  ;; also fetch channel dependencies
  (let* ((metadata (read-channel-metadata-from-source checkout-dir))
         (dependencies (channel-metadata-dependencies metadata)))
    (for-each
      (lambda (dependency)
        (fetch-channel
          (channel-url dependency)
          (or (channel-commit dependency)
              (channel-branch dependency)
              "master")
          (channel-introduction dependency)))
      dependencies))

  checkout-dir)

(define* (fetch-boxes file #:optional (channel #f))
  "Locally checkout and authenticate boxes specified in FILE.  Previous
checkouts are cached."
  (define toy-boxes
    (if channel
      (filter
        (lambda (box)
          (equal? channel
                  (symbol->string (channel-name (toys-box-channel box)))))
        (primitive-load file))
      (primitive-load file)))

  (define result
    (map
      (lambda (box)
        (with-exception-handler
          (lambda (exception)
            (format (current-error-port)
              "Error while pulling ~s channel: ~s\n"
              (channel-name (toys-box-channel box)) exception)
            #f)
          (lambda ()
            (let*
              ((channel (toys-box-channel box))
               (url (channel-url channel))
               (name (channel-name channel))
               (ref (or (channel-commit channel)
                        (channel-branch channel)
                        "master"))
               (introduction (channel-introduction channel))
               (checkout-dir (fetch-channel url ref introduction))
               (channel-metadata (read-channel-metadata-from-source checkout-dir))
               (dir (channel-metadata-directory channel-metadata))
               (commit (with-repository
                         checkout-dir repository
                         (oid->string
                           (reference-target (repository-head repository))))))
              `((box . ,box)
                (dir . ,dir)
                (commit . ,commit)
                (checkout-dir . ,checkout-dir)
                (module-dir . ,(string-append checkout-dir dir)))))
          #:unwind? #t))
      toy-boxes))

  (filter identity result))

(define (for-each-symbol fn box-wrapper)
  (let*
    ((box (assoc-ref box-wrapper 'box))
     (dir (assoc-ref box-wrapper 'module-dir))
     ;; FIXME: this leaks memory, there should be a way to remove modules
     ;; after they are resolve-interface'd and scanned.
     (modules (scheme-modules dir #:warn warn-about-load-error)))
    (for-each
      (lambda (module)
        ;; Walk public interfaces one module at a time: a single module
        ;; with a broken interface (e.g. a re-export of an unbound
        ;; variable) must skip that module, not abort the whole channel.
        (with-exception-handler
          (lambda (exception)
            (format (current-error-port)
              "guix toys: warning: skipping module ~s: ~s\n"
              (module-name module) exception)
            #f)
          (lambda ()
            (fold-module-public-variables*
              (lambda (module symbol variable result)
                (apply fn (list box module symbol variable box-wrapper)))
              '()
              (list module)))
          #:unwind? #t))
      modules)))

(define (dependency-load-paths dependency)
  "Load paths contributed by DEPENDENCY's cached checkout (honoring its
module directory) and, recursively, by its own dependencies."
  (with-exception-handler
    (lambda (exception) '())
    (lambda ()
      (let* ((dir (url-cache-directory
                    (channel-url dependency)
                    (%repository-cache-directory)))
             (metadata (read-channel-metadata-from-source dir))
             (subdir (channel-metadata-directory metadata))
             (dependencies (channel-metadata-dependencies metadata)))
        (cons (string-append dir subdir)
              (append-map dependency-load-paths dependencies))))
    #:unwind? #t))

(define (boxes-load-paths boxes)
  (let* ((boxes-without-guix
           (filter
             (lambda (box-wrapper)
               (not (equal? 'guix
                            (channel-name
                              (toys-box-channel (assoc-ref box-wrapper 'box))))))
             boxes))
         (load-paths
           (map
             (lambda (box-wrapper)
               ;; .guix-channel lives at the checkout root, not in the
               ;; channel's (directory ...) subdir — reading metadata from
               ;; module-dir loses all dependencies for channels that set a
               ;; directory (e.g. x-files).
               (let* ((module-dir (assoc-ref box-wrapper 'module-dir))
                      (checkout-dir (or (assoc-ref box-wrapper 'checkout-dir)
                                        module-dir))
                      (metadata (read-channel-metadata-from-source checkout-dir))
                      (dependencies (channel-metadata-dependencies metadata)))
                 ;; Dependencies must be walked transitively: a channel
                 ;; depending on rde gets nonguix through it, and modules
                 ;; importing (nonguix ...) fail to load otherwise.
                 (cons
                   module-dir
                   (append-map dependency-load-paths dependencies))))
             boxes-without-guix)))
    (fold append '() load-paths)))

(define (for-each-box fn boxes)
  (define old-load-path %load-path)
  (set! %load-path
    (append (boxes-load-paths boxes) %load-path))

  (for-each
    (lambda (box-wrapper)
      (with-exception-handler
        (lambda (exception)
          ;; FIXME: how the hell is one supposed to print errors in this
          ;; language properly?
          (format (current-error-port)
            "Error while scanning ~s channel: ~s\n"
            (channel-name (toys-box-channel (assoc-ref box-wrapper 'box)))
            exception)
          #f)
        (lambda () (fn box-wrapper))
        #:unwind? #t))
    boxes)

  (set! %load-path old-load-path))
