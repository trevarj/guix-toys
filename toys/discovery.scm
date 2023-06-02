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

(define-module (toys discovery)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix channels)
  #:use-module ((guix discovery) #:prefix guix:)
  #:use-module (guix memoization)
  #:use-module (guix describe)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-71)

  #:export (%current-channels
            all-channels
            all-packages
            all-modules
            all-service-types
            all-public-symbols
            location-channels))

(define %current-channels
  (string-append (getenv "HOME")
                 "/.config/guix/channels.scm"))

;; Copied from (gnu packages).
(define %distro-root-directory
  ;; Absolute file name of the module hierarchy.  Since (gnu packages …) might
  ;; live in a directory different from (guix), try to get the best match.
  (letrec-syntax ((dirname* (syntax-rules ()
                              ((_ file)
                               (dirname file))
                              ((_ file head tail ...)
                               (dirname (dirname* file tail ...)))))
                  (try      (syntax-rules ()
                              ((_ (file things ...) rest ...)
                               (match (search-path %load-path file)
                                 (#f
                                  (try rest ...))
                                 (absolute
                                  (dirname* absolute things ...))))
                              ((_)
                               #f))))
    (try ("gnu/packages/base.scm" gnu/ packages/)
         ("gnu/packages.scm"      gnu/)
         ("guix.scm"))))

;; Copied from (guix discovery) and modified to work with any location instead
;; of only packages.
(define (location-channels location)
  "Return the list of channels providing LOCATION or an empty list if it could
not be determined."
  (match (and=> location location-file)
    (#f '())
    (file
     (let ((file (if (string-prefix? "/" file)
                     file
                     (search-path %load-path file))))
       (if (and file
                (string-prefix? (%store-prefix) file))
           (filter-map
            (lambda (entry)
              (let ((item (manifest-entry-item entry)))
                (and (string-prefix? item file)
                     (manifest-entry-channel entry))))
            (current-profile-entries))
           '())))))

(define all-channels
  (mlambda ()
    "Returns the list of all channels defined in channels.scm."
    (filter-map manifest-entry-channel
                (current-profile-entries))))

;; List of all modules in Guix and installed channels.
(define all-modules
  (mlambda ()
    (guix:all-modules
      (cons* %distro-root-directory
             (%package-module-path)))))

(define all-packages
  (mlambda ()
    "Returns the list of all packages defined in %package-module-path."
    (fold-packages (lambda (package result)
                    (if (package-superseded package)
                      result
                      (cons package
                            result)))
                  '()
                  (all-modules))))

(define all-service-types
  (mlambda ()
    "Returns the list of all service types defined in %package-module-path."
    (fold-service-types (lambda (service-type result)
                          (cons service-type
                                result))
                        '()
                        (all-modules))))

(define all-public-symbols
  (mlambda ()
    "Returns the list of all public (exported) symbols defined in
%package-module-path."
    (guix:fold-module-public-variables*
      (lambda (module symbol variable result)
        (cons
          `(("name" . ,symbol)
            ("module" . ,module)
            ("variable" . ,variable))
          result))
      '()
      (all-modules))))
