;; Trimmed channel list for CI smoke runs and local frontend development.
;; Mirrors entries from channels.scm — keep these in sync if upstream changes them.
(use-modules (guix channels)
             (toys discovery))

(list
  (toys-box
   (forge "codeberg")
   (synopsis "Personal channel of Firefly.  Mostly focussed on services.")
   (channel
    (channel
     (name 'firefly)
     (url "https://codeberg.org/Firefly707/firefly-channel")
     (branch "main")
     (introduction
      (make-channel-introduction
       "8fd3d165ad053eda93ddb915d5dedc9e880c8fb5"
       (openpgp-fingerprint
        "E76F D6F5 4BCF 096F 28BB  C2A0 A026 E5A7 C382 793E"))))))

  (toys-box
    (forge "codeberg")
    (channel (channel
               (name 'rosenthal)
               (url "https://codeberg.org/hako/rosenthal")
               (branch "trunk")
               (introduction
                 (make-channel-introduction
                   "7677db76330121a901604dfbad19077893865f35"
                   (openpgp-fingerprint
                     "13E7 6CD6 E649 C28C 3385  4DF5 5E5A A665 6149 17F7"))))))

  (toys-box
    (forge "sourcehut")
    (channel (channel
               (name 'trevdev)
               (url "https://git.sr.ht/~trevdev/guix-channel")
               (branch "main")))))
