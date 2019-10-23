# nix-doom-emacs

Nix expression to install and configure
[doom-emacs](https://github.com/hlissner/doom-emacs).

The expression builds a `doom-emacs` distribution with dependencies
pre-installed based on an existing `~/.doom.d` directory.

It is not a fully fledged exprerience as some dependenices are not installed and
some may not be fully compatible as the version available in NixOS or
[emacs-overlay](https://github.com/nix-community/emacs-overlay) may not be
compatible with the `doom-emacs` requirements.

## Getting started

Using [home-manager](https://github.com/rycee/home-manager):

 ``` nix
{ pkgs, ... }:

let
  doomPrivateDir = ./doom.d;

  doom-emacs = pkgs.callPackage (builtins.fetchTarball {
    url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
  }) { inherit doomPrivateDir; };
in {
  home.packages = [ doom-emacs ];
  home.file.".doom.d".source = doomPrivateDir;
  home.file.".emacs.d".source = doom-emacs.emacsd;
}
```

## Under the hood

This expression leverages
[nix-straight.el](https://github.com/vlaci/nix-straight.el) under the hood for
installing depdendencies. The restrictions of that package apply here too.
