_:
let
  username = "cfcosta";
  home = "/Users/${username}";
in
{
  dusk = {
    inherit username;

    name = "Cainã Costa";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    folders = {
      inherit home;

      code = "${home}/Code";
    };

    shell.environmentFile = "${home}/dusk-env.sh";
    tmux.showBattery = true;
  };
}
