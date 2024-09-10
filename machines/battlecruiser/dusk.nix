_:
let
  username = "cfcosta";
  home = "/home/${username}";
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
  };
}
