{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.devos.home.vscode;
  moonlight-theme = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "moonlight";
      publisher = "atomiks";
      version = "0.10.6";
      sha256 = "2Du/2rLWZUMo746rVWnngj0f0/H/94bt3rF+G+3Ipqw=";
    };
    meta = { license = lib.licenses.mit; };
  };
  direnv-vscode = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "direnv";
      publisher = "mkhl";
      version = "0.6.1";
      sha256 = "5/Tqpn/7byl+z2ATflgKV1+rhdqj+XMEZNbGwDmGwLQ=";
    };
    meta = { license = lib.licenses.bsd0; };
  };
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
        # Theme
        moonlight-theme

        # Environment Setup
        direnv-vscode
        eamodio.gitlens
        kamikillerto.vscode-colorize

        # Language Support
        jnoortheen.nix-ide
        bungcip.better-toml
        matklad.rust-analyzer
      ] ++ optionals cfg.vimMode [ vscodevim.vim ];

    programs.vscode.userSettings = {
      "workbench.colorTheme" = "Moonlight II";
      "editor.semanticHighlighting.enabled" = true;
      "window.menuBarVisibility" = "toggle";
      "editor.fontSize" = cfg.fontSize;
    };
  };
}
