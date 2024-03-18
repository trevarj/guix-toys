;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2024 unwox <me@unwox.com>
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

(define-module (toys cmd clone)
  #:use-module (guix base32)
  #:use-module ((guix build download) #:prefix build:)
  #:use-module (guix build utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix hg-download)
  #:use-module (guix packages)
  #:use-module (ice-9 iconv)
  #:use-module (json)

  #:export (serialize-origin
            deserialize-origin
            clone-origin))

(define (serialize-origin origin)
  (let* ((uri (origin-uri origin))
         (serialized-uri
           (cond
             ((string? uri) (vector uri))
             ((list? uri) (list->vector uri))
             ((git-reference? uri)
               `(("url" . ,(git-reference-url uri))
                 ("commit" . ,(git-reference-commit uri))
                 ("recursive?" . ,(git-reference-recursive? uri))))
             ((hg-reference? uri)
               `(("url" . ,(hg-reference-url uri))
                 ("changeset" . ,(hg-reference-changeset uri))))
             (else (error (format #f "Unknown uri type: ~a" uri)))))
         (method (origin-method origin))
         (serialized-method
           (cond
             ((eq? method url-fetch) "url-fetch")
             ((eq? method url-fetch/tarbomb) "url-fetch/tarbomb")
             ((eq? method url-fetch/zipbomb) "url-fetch/zipbomb")
             ((eq? method git-fetch) "git-fetch")
             ((eq? method hg-fetch) "hg-fetch")
             (else (error (format #f "Unknown method: ~a" method)))))
         (hash (origin-hash origin))
         (serialized-hash `(("algorithm" . ,(symbol->string
                                             (content-hash-algorithm hash)))
                            ("value" . ,(bytevector->nix-base32-string
                                         (content-hash-value hash))))))
  `(("method" . ,serialized-method)
    ("uri" . ,serialized-uri)
    ("hash" . ,serialized-hash))))

(define (deserialize-origin _origin)
  (let* ((_method (assoc-ref _origin "method"))
         (deserialized-method
           (cond
             ((string=? "url-fetch" _method)
               url-fetch)
             ((string=? "url-fetch/tarbomb" _method)
               url-fetch/tarbomb)
             ((string=? "url-fetch/zipbomb" _method)
               url-fetch/zipbomb)
             ((string=? "git-fetch" _method)
               git-fetch)
             ((string=? "hg-fetch" _method)
               hg-fetch)))
         (_uri (assoc-ref _origin "uri"))
         (deserialized-uri
           (cond
             ((or (eq? deserialized-method url-fetch)
                  (eq? deserialized-method url-fetch/tarbomb)
                  (eq? deserialized-method url-fetch/zipbomb))
              (vector->list _uri))
             ((eqv? deserialized-method git-fetch)
              (git-reference
                (url (assoc-ref _uri "url"))
                (commit (assoc-ref _uri "commit"))
                (recursive? (assoc-ref _uri "recursive?"))))
             ((eqv? deserialized-method hg-fetch)
              (hg-reference
                (url (assoc-ref _uri "url"))
                (changeset (assoc-ref _uri "changeset"))))
             (else (error (format #f "Unknown uri: ~a" _uri)))))
         (deserialized-hash
           (nix-base32-string->bytevector
            (assoc-ref (assoc-ref _origin "hash") "value"))))
    (origin
      (method deserialized-method)
      (uri deserialized-uri)
      (sha256 deserialized-hash))))

(define* (clone-origin origin directory #:key ref)
  (let* ((build-method (origin-method origin))
         (method (cond
                   ((or (eq? build-method url-fetch)
                        (eq? build-method url-fetch/tarbomb)
                        (eq? build-method url-fetch/zipbomb)) url-clone)
                   ((eq? build-method git-fetch) git-clone)
                   ((eq? build-method hg-fetch) hg-clone)
                   (else (error (format #f "Can't clone with given method: ~a."
                                        build-method)))))
         (params (cond
                   ((eq? method url-clone)
                     (list (origin-uri origin) directory
                           #:bomb? (or (eq? build-method url-fetch/tarbomb)
                                       (eq? build-method url-fetch/zipbomb))))
                   ((eq? method git-clone)
                     (list (git-reference-url (origin-uri origin))
                           directory
                           #:recursive?
                           (git-reference-recursive? (origin-uri origin))))
                   ((eq? method hg-clone)
                    (list (hg-reference-url (origin-uri origin))
                          directory)))))
    (apply method params)))

(define* (git-clone url directory #:key ref recursive?)
  (when (directory-exists? directory)
    (error (format #f "Directory ~a already exists" directory)))

  (let ((params (filter
                  (negate unspecified?)
                  (list "guix" "shell" "--container" "--network"
                        "git" "openssl" "nss-certs"
                        "--" "git" "clone" (when recursive? "--recurse-submodules")
                        url directory))))
    (apply invoke params))

  (when ref
    (with-directory-excursion directory
      (invoke "guix" "shell" "git" "--" "git" "checkout" ref))))

(define* (hg-clone url directory #:key changeset)
  (when (directory-exists? directory)
    (error (format #f "Directory ~a already exists" directory)))

  (invoke "guix" "shell" "--container" "--network"
          "mercurial" "openssl" "nss-certs" "--"
          "hg" "clone" url directory)

  (when changeset
    (with-directory-excursion directory
      (invoke "guix" "shell" "--container" "mercurial" "--"
              "hg" "update" changeset))))

(define* (url-clone url directory #:key bomb?)
  ;; FIXME: run in a container
  ;; TODO: support gzip and zip
  (when (directory-exists? directory)
    (error (format #f "Directory ~a already exists" directory)))

  (let* ((tmp-file "/tmp/guix-toys-package-clone")
         (args (filter
                 (negate unspecified?)
                 (list "tar" "xvf" tmp-file "-C" directory
                       (when (not bomb?) "--strip-components" "1")
                       (when (not bomb?) "1")))))
    (build:url-fetch url tmp-file #:mirrors %mirrors)
    (mkdir directory)
    (apply invoke args)
    (delete-file tmp-file)))
