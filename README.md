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
  doom-emacs = pkgs.callPackage (builtins.fetchTarball {
    url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
  }) {
    doomPrivateDir = ./doom.d;  # Directory containing your config.el init.el
                                # and packages.el files
  };
in {
  home.packages = [ doom-emacs ];
  home.file.".emacs.d/init.el".text = ''
      (load "default.el")
  '';
}
```

## Under the hood

This expression leverages
[nix-straight.el](https://github.com/vlaci/nix-straight.el) under the hood for
installing depdendencies. The restrictions of that package apply here too.

## Usage

instead of running emacs.d/bin/doom, once you have update your config files (packages.el, init.el, config.el), rebuild doom-emacs with nix. If you are using home-manager, simply run `home-manager switch`

## Troubleshooting

On macOS on a fresh install, you might run into the error `Too many files open`. running `ulimit -S -n 2048` will only work for the duration of your shell and will fix the error
