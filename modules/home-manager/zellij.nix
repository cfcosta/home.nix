{ config, pkgs, ... }: {
  programs.zellij.enable = true;

  home.file.".config/zellij/config.kdl".text =
    builtins.readFile ../../templates/zellij.kdl;
}
