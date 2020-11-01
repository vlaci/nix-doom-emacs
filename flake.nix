/* Usage example in flake.nix:

  {
    inputs = {
      home-manager.url = "github:rycee/home-manager";
      nix-doom-emacs.url = "github:vlaci/nix-doom-emacs/flake";
    };

    outputs = {
      self,
      nixpkgs,
      home-manager,
      nix-doom-emacs,
      ...
    }: {
      nixosConfigurations.exampleHost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.users.exampleUser = { pkgs, ... }: {
              imports = [ nix-doom-emacs.hmModule ];
              home.doom-emacs = {
                enable = true;
                doomPrivateDir = ./path/to/doom.d;
              };
            };
          }
        ];
      };
    };
  }
*/

{
  description = "nix-doom-emacs home-manager module";

  inputs = {
    doom-emacs.url = "github:hlissner/doom-emacs/develop";
    doom-emacs.flake = false;
    doom-snippets.url = "github:hlissner/doom-snippets";
    doom-snippets.flake = false;
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.flake = false;
    emacs-so-long.url = "github:hlissner/emacs-so-long";
    emacs-so-long.flake = false;
    evil-markdown.url = "github:Somelauw/evil-markdown";
    evil-markdown.flake = false;
    evil-org-mode.url = "github:hlissner/evil-org-mode";
    evil-org-mode.flake = false;
    evil-quick-diff.url = "github:rgrinberg/evil-quick-diff";
    evil-quick-diff.flake = false;
    explain-pause-mode.url = "github:lastquestion/explain-pause-mode";
    explain-pause-mode.flake = false;
    "nix-straight.el".url = "github:vlaci/nix-straight.el/v2.1.0";
    "nix-straight.el".flake = false;
    nose.url= "github:emacsattic/nose";
    nose.flake = false;
    ob-racket.url = "github:xchrishawk/ob-racket";
    ob-racket.flake = false;
    org-mode.url = "github:emacs-straight/org-mode";
    org-mode.flake = false;
    org-yt.url = "github:TobiasZawada/org-yt";
    org-yt.flake = false;
    php-extras.url = "github:arnested/php-extras";
    php-extras.flake = false;
    "reveal.js".url = "github:hakimel/reveal.js";
    "reveal.js".flake = false;
    "rotate-text.el".url = "github:debug-ito/rotate-text.el";
    "rotate-text.el".flake = false;
  };

  outputs = inputs: {
      hmModule = import ./modules/home-manager.nix inputs;
  };
}
