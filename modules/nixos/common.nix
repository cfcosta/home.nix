{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "22.05";

  users.users.${config.devos.user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
