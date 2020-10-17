{ self, ... }@inputs:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.doom-emacs;
  inherit (lib) literalExample mkEnableOption mkIf mkOption types;
in
{
  options.programs.doom-emacs = {
    enable = mkEnableOption "Doom Emacs configuration";
    doomPrivateDir = mkOption {
      description = ''
        Path to your `.doom.d` directory.

        The specified directory should  contain yoour `init.el`, `config.el` and
        `packages.el` files.
      '';
      apply = path: builtins.path { inherit path; };
    };
    extraConfig = mkOption {
      description = ''
        Extra configuration options to pass to doom-emacs.

        Elisp code set here will be appended at the end of `config.el`. This
        option is useful for refering `nixpkgs` derivation in Emacs without the
        need to install them globally.
      '';
      type = with types; lines;
      default = "";
      example = literalExample ''
        (setq mu4e-mu-binary = "''${pkgs.mu}/bin/mu")
      '';
    };
    extraPackages = mkOption {
      description = ''
        Extra packages to install.

        List addition non-emacs packages here that ship elisp emacs bindings.
      '';
      type = with types; listOf package;
      default = [ ];
      example = literalExample "[ pkgs.mu ]";
    };
    package = mkOption {
      internal = true;
    };
  };

  config = mkIf cfg.enable (
    let
      emacs = pkgs.callPackage self {
        extraPackages = (epkgs: cfg.extraPackages);
        inherit (cfg) doomPrivateDir extraConfig;
        dependencyOverrides = inputs;
      };
    in
    {
      home.file.".emacs.d/init.el".text = ''
        (load "default.el")
      '';
      home.packages = with pkgs; [
        emacs-all-the-icons-fonts
      ];
      programs.emacs.package = emacs;
      programs.emacs.enable = true;
      programs.doom-emacs.package = emacs;
    }
  );
}
