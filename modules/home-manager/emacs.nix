{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.devos.home.emacs;
  emacsPackage = if cfg.graphical then
    (if cfg.wayland then pkgs.emacsPgtk else pkgs.emacsUnstable)
  else
    pkgs.emacsUnstable-nox;
in {
  options = {
    devos.home.emacs = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      theme = mkOption {
        type = types.str;
        default = "doom-moonlight";
      };

      wayland = mkEnableOption "wayland";
      graphical = mkEnableOption "graphical";

      fonts.fixed = {
        family = mkOption {
          type = types.str;
          default = "SauceCodePro Nerd Font";
        };

        weight = mkOption {
          type = types.str;
          default = "medium";
        };

        size = mkOption {
          type = types.str;
          default = "18";
        };
      };

      fonts.variable = {
        family = mkOption {
          type = types.str;
          default = "SauceCodePro Nerd Font";
        };

        weight = mkOption {
          type = types.str;
          default = "medium";
        };

        size = mkOption {
          type = types.str;
          default = "16";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.doom-emacs = {
      enable = true;
      doomPrivateDir = ../../templates/doom-emacs;
      emacsPackage = if cfg.graphical then
        (if cfg.wayland then pkgs.emacsPgtk else pkgs.emacsUnstable)
      else
        pkgs.emacsUnstable-nox;
    };

    home.packages = with pkgs; [
      nixfmt
      nodePackages.bash-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.mermaid-cli
      nodePackages.typescript-language-server
      nodePackages.vscode-json-languageserver
      nodePackages.yaml-language-server
    ];

    home.file.".doom.d/nix.init.el".text = with cfg; ''
      (setq user-full-name "${config.devos.home.name}"
            user-mail-address "${config.devos.home.email}")

      (setq auth-sources '("~/.authinfo"))

      (setq doom-theme '${theme})
      (setq doom-font (font-spec :family "${fonts.fixed.family}" :weight '${fonts.fixed.weight} :size ${fonts.fixed.size})
            doom-variable-pitch-font (font-spec :family "${fonts.variable.family}" :weight '${fonts.variable.weight} :size ${fonts.variable.size}))
    '';

    services.emacs.enable = true;
  };
}
