(use-modules (guix channels)
             (toys discovery))

(list
  (toys-box
    (forge "gitea")
    (channel
      (channel
        (name 'emacs-master)
        (url "https://codeberg.org/akib/guix-channel-emacs-master")
        (introduction
         (make-channel-introduction
          "1ba8c40e21c1c18f70c8ff116f2fbbbb41a5a30a"
          (openpgp-fingerprint
           "C954 CA9A BB4B EA43 417B  7151 5535 FCF5 4D88 616B"))))))
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
                (name 'rust-next)
                (url "https://github.com/umanwizard/guix-rust-next")
                (branch "master"))))
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
                   "f260da13666cd41ae3202270784e61e062a3999c"
                   (openpgp-fingerprint
                     "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))))
  (toys-box
    (forge "gitlab")
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
               "0a0cbe82ff9786f3b072e573ce426619e33029b1"
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
   #;(toys-box
     (forge "sourcehut")
     (channel (channel
                (name 'confetti)
                (url "https://git.sr.ht/~whereiseveryone/confetti")
                (branch "e")
                (introduction
                 (make-channel-introduction
                  "e037ffa3a40bcd7807a97a0415ef588b411277c3"
                  (openpgp-fingerprint
                   "3B1D 7F19 E36B B60C 0F5B  2CA9 A52A A2B4 77B6 DD35"))))))
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
               (name 'bin-guix)
               (url "https://github.com/ieugen/bin-guix")
               (branch "main"))))
  (toys-box
    (forge "sourcehut")
    (channel (channel
               (name 'sokolov)
               (url "https://git.sr.ht/~sokolov/channel"))))
  (toys-box
    (forge "github")
    (channel (channel
               (name 'tassos-guix)
               (url "https://github.com/Tass0sm/tassos-guix"))))
  (toys-box
   (forge "github")
   (channel (channel
             (name 'sheepfold)
             (url "https://github.com/dochang/sheepfold"))))
  (toys-box
   (forge "github")
   (channel (channel
             (name 'engstrand)
             (url "https://github.com/engstrand-config/guix-dotfiles")
             (branch "main")
             (introduction
              (make-channel-introduction
               "005c42a980c895e0853b821494534d67c7b85e91"
               (openpgp-fingerprint
                "C9BE B8A0 4458 FDDF 1268 1B39 029D 8EB7 7E18 D68C"))))))
  (toys-box
    (forge "sourcehut")
    (channel (channel
               (name 'mobilizon-reshare)
               (url "https://git.sr.ht/~fishinthecalculator/mobilizon-reshare-guix")
               (branch "main"))))
  #;(toys-box
    (forge "github")
    (channel (channel
                (name 'th)
                (url "https://github.com/TinHead/th-guix-channel")
                (branch "main"))))
  (toys-box
    (forge "sourcehut")
    (channel (channel
               (name 'atlas)
               (url "https://git.sr.ht/~michal_atlas/guix-channel")
               (branch "master")
               (introduction
                 (make-channel-introduction
                   "f0e838427c2d9c495202f1ad36cfcae86e3ed6af"
                   (openpgp-fingerprint
                     "D451 85A2 755D AF83 1F1C  3DC6 3EFB F2BB BB29 B99E"))))))
  (toys-box
    (forge "gitea")
    (channel (channel
               (name 'ngapsh)
               (url "https://codeberg.org/Parnikkapore/guix-ngapsh-unsigned")
               (branch "main"))))
  (toys-box
    (forge "github")
    (channel (channel
            (name 'hui)
            (url "https://github.com/newluhux/guix-hui")
            (branch "master"))))
  (toys-box
   (forge "gitea")
   (channel (channel
             (name 'noisytoot)
             (url "https://git.noisytoot.org/noisytoot/guix-channel")
             (branch "master")
             (introduction
              (make-channel-introduction
               "9e5feb9b9c7a92b28f8b8fe737b13f5ca786e0a1"
               (openpgp-fingerprint
                "61C5 28F6 1F2C FADA 9526  A45B 1D43 EF4F 4492 268B"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'kbg)
             (url "https://git.sr.ht/~kennyballou/guix-channel.git")
             (branch "master")
             (introduction
              (make-channel-introduction
               "b9d0b8041d28ebd9f85cb041aa3f2235c8b39417"
               (openpgp-fingerprint
                "10F4 14AB D526 0D0E 2372  8C08 FE55 890B 57AE DCE5"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'ffab)
             (url "https://git.sr.ht/~hellseher/ffab")
             (branch "main"))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'rrr)
             (url "https://git.sr.ht/~akagi/rrr")
             (branch "master")
             (introduction
              (make-channel-introduction
               "794d6e5eb362bfcf81ada12b6a49a0cd55c8e031"
               (openpgp-fingerprint
                "FF72 877C 4F21 FC4D 467D  20C4 DCCB 5255 2098 B6C1"))))))
  (toys-box
   (forge "cgit")
   (channel
    (channel
     (name 'gn-bioinformatics)
     (url "https://git.genenetwork.org/guix-bioinformatics/")
     (branch "master"))))
  (toys-box
   (forge "sourcehut")
   (channel
    (channel
     (name 'benoitj)
     (url "https://git.sr.ht/~benoit/my-guix-channel")
     (branch "main")
     (introduction
      (make-channel-introduction
       "37444eebf69f83f4accaa2c69562209d94f4e57a"
       (openpgp-fingerprint
        "C3B6 ED99 DF87 B208 0C79  C8AC F86B 0628 26D4 C20A"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'sops-guix)
             (url "https://git.sr.ht/~fishinthecalculator/sops-guix")
             (branch "main")
             (introduction
              (make-channel-introduction
               "0bbaf1fdd25266c7df790f65640aaa01e6d2dbc9"
               (openpgp-fingerprint
                "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'gocix)
             (url "https://git.sr.ht/~fishinthecalculator/gocix")
             (branch "main")
             (introduction
              (make-channel-introduction
               "cdb78996334c4f63304ecce224e95bb96bfd4c7d"
               (openpgp-fingerprint
                "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2"))))))
  (toys-box
   (forge "github")
   (channel (channel
             (name 'guixcn)
             (url "https://github.com/guixcn/guix-channel")
             (branch "master")
             (introduction
              (make-channel-introduction
               "993d200265630e9c408028a022f32f34acacdf29"
               (openpgp-fingerprint
                "7EBE A494 60CE 5E2C 0875  7FDB 3B5A A993 E1A2 DFF0"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'yewscion)
             (url "https://git.sr.ht/~yewscion/yewscion-guix-channel")
             (branch "trunk")
             (introduction
              (make-channel-introduction
               "2dce8bfec5f2886f7642007bbead3f2fbee26312"
               (openpgp-fingerprint
                "24C4 1BBD 8571 BD9D 1E17  FF38 5D9E 8581 A195 CF7B"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'vhallac)
             (url "https://git.sr.ht/~vhallac/guix-channel")
             (introduction
              (make-channel-introduction
               "f85f577fcb5ec7257b0dce961038699fd274e052"
               (openpgp-fingerprint
                "2252 DEF9 035D 5101 4FC0  850E 1D90 9F28 0D85 F19F"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'nebula)
             (url "https://git.sr.ht/~apoorv569/nebula")
             (introduction
              (make-channel-introduction
               "2f1be757b40f78456220823b71aace5277c5f33d"
               (openpgp-fingerprint
                "53B4 8418 D76A 3EF1 1BCC  92A8 4FDB 05CF 5D67 6283"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'vf2)
             (url "https://git.sr.ht/~akagi/vf2-guix")
             (introduction
              (make-channel-introduction
               "ce522ca3fe753b502065f42bcdacb679305c3dee"
               (openpgp-fingerprint
                "FF72 877C 4F21 FC4D 467D  20C4 DCCB 5255 2098 B6C1"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'plt)
             (url "https://git.sr.ht/~plattfot/plt"))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'old)
             (url "https://git.sr.ht/~old/guix-channel")
             (introduction
              (make-channel-introduction
               "fba5d96ea99ac4a7b3ab868eab0d68b3cc7285ae"
               (openpgp-fingerprint
                "295C 0246 4AC1 92F1 FFDD  7550 FCC0 88CE 07A0 4DAE"))))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'neguix)
             (url "https://git.sr.ht/~niklaseklund/neguix")
             (branch "main")
             (introduction
              (make-channel-introduction
               "9860ea17cb21131fe5809053ffcc148ac7549465"
               (openpgp-fingerprint
                "66E6 01AC 1756 020B 759B  E34B 7B65 F79C 3247 8510"))))))
  ; (toys-box
  ;  (forge "sourcehut")
  ;  (channel (channel
  ;            (name 'hitwright)
  ;            (url "https://git.sr.ht/~hitwright/personal-guix-channel")
  ;            (branch "main"))))
  (toys-box
   (forge "sourcehut")
   (channel (channel
             (name 'efraim-dfsg)
             (url "https://git.sr.ht/~efraim/my-guix")
             (introduction
              (make-channel-introduction
               ;; "4589296d61888fa88de331d5e180713c6a268c6f"
               ;; official introduction commit doesn't work because commit with
               ;; hash 0ed36fc128c4ba52e167d8bf2bd8e0456a6a7a41 is unsigned
               "61c9f87404fcb97e20477ec379b643099e45f1db"
               (openpgp-fingerprint
                "A28B F40C 3E55 1372 662D  14F7 41AA E7DC CA3D 8351"))))))
  (toys-box
   (forge "gogs")
   (channel (channel
             (name 'wigust)
             (url "https://notabug.org/wigust/guix-wigust"))))
  (toys-box
   (forge "codeberg")
   (channel (channel
             (name 'kakafarm)
             (url "https://codeberg.org/kakafarm/guix-kakafarm-channel"))))
  (toys-box
   (forge "codeberg")
   (channel (channel
             (name 'atomized)
             (url "https://codeberg.org/ieure/atomized-guix.git")
             (branch "main")
             (introduction
              (make-channel-introduction
               "bdbcd3c5815f64799e2c0d139896da83d9972bd1"
               (openpgp-fingerprint
                "6980 A9B9 5202 AA11 EB1D  8922 8499 AC88 F1A7 1CF2"))))))
  (toys-box
    (forge "gitlab")
    (channel (channel
               (name 'suixpkgs)
               (url "https://gitlab.vulnix.sh/spacecadet/suixpkgs.git")
               (introduction
                 (make-channel-introduction
                   "dc5e12b0b485c9ee90e3224379551b72e59d846b"
                   (openpgp-fingerprint
                     "A121 9B10 8E0D 568A 07B5  CC26 487A B572 6228 CB79"))))))
  (toys-box
   (forge "gitlab")
   (channel (channel
             (name 'cdo)
             (url "https://git.mutix.org/cdo/guix-channel.git")
             (introduction
              (make-channel-introduction
               "d8d516b1d477d287ca9cee5cbd73140ed2a0bfc8"
               (openpgp-fingerprint
                "D899 861B 5EAD 198A CA06  2A9B 9DA1 DD52 53A7 AA4C"))))))
  (toys-box
   (forge "cgit")
   (channel %default-guix-channel)))
