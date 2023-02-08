(use-modules (guix records))

;; Guix channel wrapper with additional data.
(define-record-type* <toys-box>
  toys-box make-toys-box
  toys-box?

  (channel toys-box-channel)        ; channel
  (forge toys-box-forge             ; string | #f
        (default #f))
  ;; directory in repository where source code for channel is situated
  ;; TODO: parse from .guix-channel file?
  (directory toys-box-directory     ; string | #f
             (default #f)))

(define toys-boxes
  (list
    (toys-box
      (forge "sourcehut")
      (channel (channel
                 (name 'guixrus)
                 (url "https://git.sr.ht/~whereiseveryone/guixrus")
                 (introduction
                   (make-channel-introduction
                     "7c67c3a9f299517bfc4ce8235628657898dd26b2"
                     (openpgp-fingerprint
                       "CD2D 5EAA A98C CB37 DA91  D6B0 5F58 1664 7F8B E551"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'emacs)
                 (url "https://github.com/babariviere/guix-emacs")
                 (introduction
                   (make-channel-introduction
                     "72ca4ef5b572fea10a4589c37264fa35d4564783"
                     (openpgp-fingerprint
                       "261C A284 3452 FB01 F6DF  6CF4 F9B7 864F 2AB4 6F18"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'druix)
                 (url "https://github.com/drewc/druix")
                 (branch "main"))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'flat)
                 (url "https://github.com/flatwhatson/guix-channel")
                 (introduction
                   (make-channel-introduction
                     "33f86a4b48205c0dc19d7c036c85393f0766f806"
                     (openpgp-fingerprint
                       "736A C00E 1254 378B A982  7AF6 9DBE 8265 81B6 4490"))))))
    (toys-box
      (forge "gitlab")
      (channel (channel
                 (name 'guix-hpc)
                 (url "https://gitlab.inria.fr/guix-hpc/guix-hpc"))))
    (toys-box
      (forge "sourcehut")
      (directory "src")
      (channel (channel
                 (name 'rde)
                 (url "https://git.sr.ht/~abcdw/rde")
                 (introduction
                   (make-channel-introduction
                     "257cebd587b66e4d865b3537a9a88cccd7107c95"
                     (openpgp-fingerprint
                       "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0"))))))
    (toys-box
      (forge "sourcehut")
      (channel (channel
                 (name 'rg)
                 (url "https://git.sr.ht/~raghavgururajan/guix-channel")
                 (introduction
                   (make-channel-introduction
                     "b56a4dabe12bfb1eed80467f48d389b32137cb60"
                     (openpgp-fingerprint
                       "CD2D 5EAA A98C CB37 DA91  D6B0 5F58 1664 7F8B E551"))))))
    (toys-box
      (forge "sourcehut")
      (channel (channel
                 (name 'unwox)
                 (url "https://git.sr.ht/~unwox/guix-pkgs")
                 (introduction
                   (make-channel-introduction
                     "9e7a681dece5688c792755bf047f664fb859b47a"
                     (openpgp-fingerprint
                       "43E6 223B 3497 270A 6162  82FF B675 80AB 5694 9C84"))))))
    (toys-box
      (forge "gitlab")
      (channel (channel
                 (name 'small-guix)
                 (url "https://gitlab.com/orang3/small-guix")
                 (introduction
                   (make-channel-introduction
                     "940e21366a8c986d1e10a851c7ce62223b6891ef"
                     (openpgp-fingerprint
                       "D088 4467 87F7 CBB2 AE08  BE6D D075 F59A 4805 49C3"))))))
    (toys-box
      (forge "gitlab")
      (directory "modules")
      (channel (channel
                 (name 'guix-past)
                 (url "https://gitlab.inria.fr/guix-hpc/guix-past")
                 (introduction
                   (make-channel-introduction
                     "0c119db2ea86a389769f4d2b9c6f5c41c027e336"
                     (openpgp-fingerprint
                       "3CE4 6455 8A84 FDC6 9DB4  0CFB 090B 1199 3D9A EBB5"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'guix-science)
                 (url "https://github.com/guix-science/guix-science")
                 (introduction
                   (make-channel-introduction
                     "b1fe5aaff3ab48e798a4cce02f0212bc91f423dc"
                     (openpgp-fingerprint
                       "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))))
    (toys-box
      (forge "cgit")
      (channel (channel
                 (name 'guix-forge)
                 (url "https://git.systemreboot.net/guix-forge/")
                 (branch "main")
                 (introduction
                   (make-channel-introduction
                     "0432e37b20dd678a02efee21adf0b9525a670310"
                     (openpgp-fingerprint
                       "7F73 0343 F2F0 9F3C 77BF  79D3 2E25 EE8B 6180 2BB3"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'crypto)
                 (url "https://github.com/attila-lendvai/guix-crypto")
                 (branch "main")
                 (introduction
                   (make-channel-introduction
                     "a6a78768c2f9d0f0e659b0788001e37e23dc26e4"
                     (openpgp-fingerprint
                       "69DA 8D74 F179 7AD6 7806  EE06 FEFA 9FE5 5CF6 E3CD"))))))
    (toys-box
      (forge "gitlab")
      (channel (channel
                 (name 'nonguix)
                 (url "https://gitlab.com/nonguix/nonguix")
                 (introduction
                   (make-channel-introduction
                     "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
                     (openpgp-fingerprint
                       "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))))
    (toys-box
      (forge "sourcehut")
      (channel (channel
                 (name 'trevdev)
                 (url "https://git.sr.ht/~trevdev/guix-channel")
                 (branch "main"))))
    (toys-box
     (forge "gitea")
     (channel (channel
               (name 'juix)
               (url "https://git.trees.st/Marie-Joseph/juix")
               (branch "main")
               (introduction
                (make-channel-introduction
                 "2910a997db86cc5a474c369e72cee7c793becb15"
                 (openpgp-fingerprint
                  "46DB B5B2 61F5 36CD 37DE E3E7 1BE8 0027 F12B 9C29"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'rosenthal)
                 (url "https://github.com/rakino/rosenthal")
                 (branch "trunk")
                 (introduction
                   (make-channel-introduction
                     "7677db76330121a901604dfbad19077893865f35"
                     (openpgp-fingerprint
                       "13E7 6CD6 E649 C28C 3385  4DF5 5E5A A665 6149 17F7"))))))
    (toys-box
      (forge "sourcehut")
      (channel (channel
                 (name 'waggle)
                 (url "https://git.sr.ht/~lunabee/waggle")
                 (branch "trunk")
                 (introduction
                   (make-channel-introduction
                     "4ffb1fd3b89f80bac196d597edf6789dd843fe48"
                     (openpgp-fingerprint
                       "4DA1 9E0B 4161 3198 F4F5  9D9C 1A5A 96AD 307C D736"))))))
    (toys-box
      (forge "gitlab")
      (channel (channel
                  (name 'guix-android)
                  (url "https://framagit.org/tyreunom/guix-android")
                  (introduction
                    (make-channel-introduction
                      "d031d039b1e5473b030fa0f272f693b469d0ac0e"
                      (openpgp-fingerprint
                        "1EFB 0909 1F17 D28C CBF9 B13A 53D4 57B2 D636 EE82"))))))
    (toys-box
      (forge "github")
      (channel (channel
                 (name 'bin-buix)
                 (url "https://github.com/ieugen/bin-guix")
                 (branch "main"))))
    (toys-box
      (forge "cgit")
      (channel %default-guix-channel))))

(define (toys-boxes->channels channels)
  (map
    (lambda (channel)
      (toys-box-channel channel))
    channels))

(toys-boxes->channels toys-boxes)
