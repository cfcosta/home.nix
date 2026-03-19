{ config, ... }:
{
  home-manager.users.${config.dusk.username} = {
    services.swaync.enable = true;
  };
}
