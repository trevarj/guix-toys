;;; GNU Guix --- Functional package management for GNU
;;;
;;; Copyright © 2022 Charles Jackson <charles.b.jackson@protonmail.com>
;;; Copyright © 2022 jgart <jgart@dismail.de>
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

(define-module (toys)
  #:use-module (web server)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 textual-ports)
  #:use-module (json)
  #:use-module (gnu packages)
  #:use-module (gnu packages suckless)
  #:use-module (guix packages)
  #:use-module (guix diagnostics))

;; Utils.

(define (package->alist package)
  "Returns alist for PACKAGE.
  Currently only support name, version, and synopsis."
  (let* ((name (package-name package))
         (version (package-version package))
         (synopsis (package-synopsis package)))
    `(("name" . ,name)
      ("version" . ,version)
      ("synopsis" . ,synopsis))))

(define (toys-api request request-body)
  (values '((content-type . (application/json)))
          (scm->json-string 
            `(("packages" . ,(vector (package->alist dwm)))))))

;; Run toys JSON API and emit package information.

(run-server toys-api)
