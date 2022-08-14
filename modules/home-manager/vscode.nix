{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home.vscode;
in {
  options = {
    devos.home.vscode = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      vimMode = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (getName pkg) [ "vscode" ];

    programs.vscode.enable = true;

    programs.vscode.extensions = with pkgs.vscode-extensions;
      [ dracula-theme.theme-dracula jnoortheen.nix-ide matklad.rust-analyzer ]
      ++ optionals cfg.vimMode [ vscodevim.vim ];

    programs.vscode.userSettings = {
      "workbench.colorTheme" = "Dracula";
      "editor.semanticHighlighting.enabled" = true;
    };
  };
}
