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
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (guix store)
  #:use-module (guix ui)
  #:use-module (guix utils)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-71)

  #:export (%current-profile
            %current-channels
            all-channels
            all-packages
            all-service-types
            all-public-symbols
            location-channels))

(define %current-profile
  (string-append (getenv "HOME")
                 "/.config/guix/current"))

(define %current-channels
  (string-append (getenv "HOME")
                 "/.config/guix/channels.scm"))

;; These are slightly modified copies of Guix functions with redefined scope:
;; by default current-profile from (guix describe) checks if running process is
;; guix command and if not returns #f.  Without proper profile scoping Guix API
;; will not return information on additional channels that may be installed on
;; the user's system.

;; XXX: is there a better way to override current-profile function?

;; (guix describe)
(define (package-path-entries)
  "Return two values: the list of package path entries to be added to the
package search path, and the list to be added to %LOAD-COMPILED-PATH.  These
entries are taken from the 'guix pull' profile the calling process lives in,
when applicable."
  (unzip2 (map (lambda (entry)
                 (list (string-append (manifest-entry-item entry)
                                      "/share/guile/site/"
                                      (effective-version))
                       (string-append (manifest-entry-item entry)
                                      "/lib/guile/" (effective-version)
                                      "/site-ccache")))
               (manifest-entries (profile-manifest %current-profile)))))

;; (gnu packages)
(define %package-module-path
  ;; Search path for package modules.  Each item must be either a directory
  ;; name or a pair whose car is a directory and whose cdr is a sub-directory
  ;; to narrow the search.
  (let* ((channels-scm _ (package-path-entries)))
    (make-parameter
     (append %default-package-module-path
             channels-scm))))

;; (guix describe)
(define current-profile-entries
  (mlambda ()
    "Return the list of entries in the 'guix pull' profile the calling process
lives in, or the empty list if this is not applicable."
    (let ((manifest (profile-manifest %current-profile)))
      (manifest-entries manifest))))

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

;; List of all modules defined in %package-module-path.
(define all-modules
  (mlambda ()
    (guix:all-modules (%package-module-path))))

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
