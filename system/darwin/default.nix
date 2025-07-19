{ config, inputs, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.default

    ./applications
    ./homebrew.nix
    ./system.nix
  ];

  config = {
    nix = {
      # Enable building Linux packages using a VM
      linux-builder.enable = true;
      settings.trusted-users = [ "@admin" ];
    };

    # Allow using Touch ID to run sudo
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };

    users = {
      knownUsers = [ config.dusk.username ];

      users."${config.dusk.username}" = {
        uid = 501;
        shell = config.home-manager.users.${config.dusk.username}.programs.bash.package;
      };
    };
  };
}
