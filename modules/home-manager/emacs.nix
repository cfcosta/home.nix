{ pkgs, lib, config, ... }:
with lib;
let cfg = config.devos.home.emacs;
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

      fonts.fixed = {
        family = mkOption {
          type = types.str;
          default = "FuraCode Nerd Font";
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
          default = "FuraCode Nerd Font";
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
      emacsPackage = pkgs.emacsNativeComp;
    };

    home.packages = with pkgs; [ nodePackages.mermaid-cli ];

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
