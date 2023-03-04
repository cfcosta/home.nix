{ pkgs, lib, config, ... }:
with lib;
let cfg = config.devos.home.lsp;
in {
  options = { devos.home.lsp.enable = mkEnableOption "lsp"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Syntax and Parsing
      tree-sitter

      # Format
      nixfmt # bash
      shfmt # shell
      devos.rustfmt # rust

      # Diagnostics
      shellcheck # bash

      # Language Servers
      rnix-lsp # nix
      nodePackages.bash-language-server # bash
      nodePackages.dockerfile-language-server-nodejs # Dockerfile
      nodePackages.typescript-language-server # Typescript
      nodePackages.vscode-json-languageserver # JSON
      nodePackages.yaml-language-server # YAML
      devos.rust-analyzer # rust
    ];
  };
}
