{ # The files would be going to ~/.config/doom (~/.doom.d)
  doomPrivateDir
  # Package set to install emacs and dependent packages from
, emacsPackages
, lib
, pkgs
, stdenv
, buildEnv
, makeWrapper
, runCommand
, fetchFromGitHub
, substituteAll
, writeScriptBin
, writeTextDir }:

let
  # Packages we need to get the default doom configuration run
  overrides = self: super: {
    evil-escape = super.evil-escape.overrideAttrs (esuper: {
      patches = [ ./evil-escape.patch ];
    });
    org-yt = self.trivialBuild rec {
      pname = "org-yt";
      version = "1";
      recipe = null;
      ename = pname;
      src = fetchFromGitHub {
        owner = "TobiasZawada";
        repo = "org-yt";
        rev = "40cc1ac76d741055cbefa13860d9f070a7ade001";
        sha256 = "0jsm3azb7lwikvc53z4p91av8qvda9s15wij153spkgjp83kld3p";
      };
    };
  };

  # Stage 1: prepare source for byte-compilation
  doomSrc = stdenv.mkDerivation {
    name = "doom-src";
    src = fetchFromGitHub {
      owner = "hlissner";
      repo = "doom-emacs";
      rev = "eb2a67d05ff4b178fedabd36ce448191cce8d6bb";
      sha256 = "05nhsn4q2bbs8m7x88ci2k7cq7hc7ql6xkyv0hmz762ip8g1jvlp";
    };
    phases = ["unpackPhase" "patchPhase" "installPhase"];
    patches = [
      (substituteAll {
        src = ./fix-paths-pre.patch;
        private = builtins.toString doomPrivateDir;
      })
    ];
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };

  # Stage 2:: install dependencies and byte-compile prepared source
  doomLocal =
    let
      straight-env = pkgs.callPackage (fetchFromGitHub {
        owner = "vlaci";
        repo = "nix-straight.el";
        rev = "v1.0";
        sha256 = "038dss49bfvpj15psh5pr9jyavivninl0rzga9cn8qyc4g2cj5i0";
      }) {
        emacsPackages = emacsPackages.overrideScope' overrides;
        emacsLoadFiles = [ ./advice.el ];
        emacsArgs = [
          "install"
          "--no-fonts"
          "--no-env"
        ];

      # Need to reference a store path here, as byte-compilation will bake-in
      # absolute path to source files.
        emacsInitFile = "${doomSrc}/bin/doom";
      };

      packages = straight-env.packageList (super: {
        phases = [ "installPhase" ];
        preInstall = ''
          export DOOMDIR=$(mktemp -d)
          export DOOMLOCALDIR=$DOOMDIR/local/
          cp ${doomPrivateDir}/* $DOOMDIR
        '';
      });

      # I don't know why but byte-compilation somehow triggers Emacs to look for
      # the git executable. It does not seem to be executed though...
      git = writeScriptBin "git" ''
        >&2 echo Executing git is not allowed; command line: "$@"
      '';
    in (straight-env.emacsEnv {
      inherit packages;
      straightDir = "$DOOMLOCALDIR/straight";
    }).overrideAttrs (super: {
      phases = [ "installPhase" ];
      buildInputs = super.buildInputs ++ [ git ];
      preInstall = ''
          export DOOMDIR=$(mktemp -d)
          export DOOMLOCALDIR=$out/
          mkdir -p $DOOMDIR
          cp ${doomPrivateDir}/* $DOOMDIR
      '';
    });

  # Stage 3: do additional fixups to refer compiled files in the store
  # and additional files in the users' home
  doom-emacs = stdenv.mkDerivation rec {
    name = "doom-emacs";
    src = doomSrc;
    patches = [
      (substituteAll {
        src = ./fix-paths.patch;
        local = doomLocal;
      })
    ];
    buildPhase = ":";
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };

  # Stage 4: catch-all wrapper capable to run doom-emacs even
  # without installing ~/.emacs.d
  emacs = (emacsPackages.emacsWithPackages (epkgs: [
    (writeTextDir "share/emacs/site-lisp/default.el" ''
        (message "doom-emacs is not placed in `doom-private-dir',
        loading from `site-lisp'")
        (when (> emacs-major-version 26)
              (load "${doom-emacs}/early-init.el"))
        (load "${doom-emacs}/init.el")
      '')
  ])).overrideAttrs (super: {
    outputs = [ "out" "emacsd" ];
    buildInputs = [ doom-emacs ];
    installPhase = super.installPhase + ''
      echo ln -snf ${doom-emacs} $emacsd
      ln -snf ${doom-emacs} $emacsd
    '';
  });

in emacs
