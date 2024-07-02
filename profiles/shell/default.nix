{ pkgs, ... }:
let
  inherit (pkgs.stdenv) isLinux;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      bashInteractive
      curl
      file
      git
      wget
    ];

    programs = {
      bash.enable = true;
      gnupg.enable = true;
    };

    system.stateVersion = if isLinux then "23.11" else 4;
  };
}
