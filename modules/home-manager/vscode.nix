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

      fontSize = mkOption {
        type = types.int;
        default = 16;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.vscode.enable = true;
    programs.vscode.package = pkgs.vscodium;

    programs.vscode.extensions = with pkgs.vscode-extensions;
      [
        dracula-theme.theme-dracula
        jnoortheen.nix-ide
        matklad.rust-analyzer
        eamodio.gitlens
        kamikillerto.vscode-colorize
      ] ++ optionals cfg.vimMode [ vscodevim.vim ];

    programs.vscode.userSettings = {
      "workbench.colorTheme" = "Dracula";
      "editor.semanticHighlighting.enabled" = true;
      "window.menuBarVisibility" = "toggle";
      "editor.fontSize" = cfg.fontSize;
    };
  };
}
