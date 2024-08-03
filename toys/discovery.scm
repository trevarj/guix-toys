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
            fold-public-symbols

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

(define (fetch-boxes file)
  "Locally checkout and authenticate boxes specified in FILE.  Previous
checkouts are cached."
  (define toy-boxes (primitive-load file))
  (map
    (lambda (box)
      (let*
        ((channel (toys-box-channel box))
         (url (channel-url channel))
         (name (channel-name channel))
         (ref
           (or (channel-commit channel)
               (channel-branch channel)
               "master"))
         (introduction
           (channel-introduction channel)))

        (format #t "Fetching ~a...\n" url)
        (define checkout-dir
         (update-cached-checkout
          url #:ref `(branch . ,ref)))

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

        (define channel-metadata
          (read-channel-metadata-from-source checkout-dir))

        (define dir
          (channel-metadata-directory channel-metadata))

        (define commit
          (with-repository checkout-dir repository
            (oid->string
              (reference-target (repository-head repository)))))

        `((box . ,box)
          (dir . ,dir)
          (commit . ,commit)
          (module-dir . ,(string-append checkout-dir dir)))))
    toy-boxes))

(define (fold-public-symbols kons knil boxes)
  "Apply KONS to the list of public symbols found in BOXES.  KNIL is an initial
value to append results to." (define old-load-path %load-path)
  (set! %load-path
    (append
      (map
        (lambda (box-wrapper)
          (assoc-ref box-wrapper 'module-dir))
        ;; Filter out guix channel, it is scanned just fine without proper
        ;; importing.
        (filter
          (lambda (box-wrapper)
            (not (equal? 'guix
                    (channel-name
                      (toys-box-channel (assoc-ref box-wrapper 'box))))))
          boxes))
      %load-path))

  (define public-symbols
    (fold
      (lambda (box-wrapper result)
        (format #t "Scanning ~a...\n"
                (symbol->string
                  (channel-name
                    (toys-box-channel (assoc-ref box-wrapper 'box)))))
        (let*
          ((box (assoc-ref box-wrapper 'box))
           (dir (assoc-ref box-wrapper 'module-dir))
           ;; FIXME: this leaks memory, there should be a way to remove modules
           ;; after they are resolve-interface'd and scanned.
           (introduction
             (channel-introduction
               (toys-box-channel box)))
           (modules
             (scheme-modules
               dir
               #:warn warn-about-load-error)))
          (append
            (fold-module-public-variables*
              (lambda (module symbol variable result)
                (apply kons
                       (list box module symbol variable box-wrapper result)))
              knil
              modules)
            result)))
      '()
      boxes))

  (set! %load-path old-load-path)
  public-symbols)
