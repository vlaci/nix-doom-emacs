{ lock, dune }:

self: super: {
  straightBuild = { pname, ... }@args: self.trivialBuild ({
    ename = pname;
    version = "1";
    src = lock pname;
    buildPhase = ":";
  } // args);

  evil-escape = super.evil-escape.overrideAttrs (esuper: {
    patches = [ ./evil-escape.patch ];
  });

  doom-snippets = self.straightBuild {
    pname = "doom-snippets";
    postInstall = ''
       cp -r *-mode $out/share/emacs/site-lisp
    '';
  };

  explain-pause-mode = self.straightBuild {
    pname = "explain-pause-mode";
  };

  evil-markdown = self.straightBuild {
    pname = "evil-markdown";
  };

  evil-org = self.straightBuild {
    pname = "evil-org-mode";
    ename = "evil-org";
  };

  evil-quick-diff = self.straightBuild {
    pname = "evil-quick-diff";
  };

  magit = super.magit.overrideAttrs (esuper: {
    preBuild = ''
      make VERSION="${esuper.version}" -C lisp magit-version.el
    '';
  });

  nose = self.straightBuild {
    pname = "nose";
  };

  org-mode = self.straightBuild rec {
    pname = "org-mode";
    version = "9.4";
    installPhase = ''
      LISPDIR=$out/share/emacs/site-lisp
      install -d $LISPDIR

      cp -r * $LISPDIR

      cat > $LISPDIR/lisp/org-version.el <<EOF
      (fset 'org-release (lambda () "${version}"))
      (fset 'org-git-version #'ignore)
      (provide 'org-version)
      EOF
    '';
  };

  org-yt = self.straightBuild {
    pname = "org-yt";
  };

  php-extras = self.straightBuild {
    pname = "php-extras";
  };

  revealjs = self.straightBuild {
    pname = "revealjs";

    installPhase = ''
      LISPDIR=$out/share/emacs/site-lisp
      install -d $LISPDIR

      cp -r * $LISPDIR
    '';
  };

  rotate-text = self.straightBuild {
    pname = "rotate-text";
  };

  so-long = self.straightBuild {
    pname = "emacs-so-long";
    ename = "so-long";
  };

  ob-racket = self.straightBuild {
    pname = "ob-racket";
  };

  # dune has a nontrivial derivation, which does not buildable from the melpa
  # wrapper falling back to the one in nixpkgs
  dune = dune.overrideAttrs (old: {
    # Emacs derivations require an ename attribute
    ename = old.pname;

    # Need to adjust paths here match what doom expects
    postInstall = ''
      mkdir -p $out/share/emacs/site-lisp/editor-integration
      ln -snf $out/share/emacs/site-lisp $out/share/emacs/site-lisp/editor-integration/emacs
    '';
  });
}
