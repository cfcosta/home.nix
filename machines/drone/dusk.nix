{ config, ... }:
let
  username = "cfcosta";
in
{
  dusk = {
    inherit username;

    name = "Cainã Costa";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";
    shell.environmentFile = "${config.dusk.folders.home}/dusk-env.sh";
    tmux.showBattery = true;
  };
}
