{ pkgs, lib }:
{
  mkUser =
    {
      name,
      user,
      email,
      accounts ? { },
    }:
    {
      users.users.${user} = {
        isNormalUser = true;
        description = name;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };

      home-manager.users.${user} = {
        programs.git = {
          enable = true;
          userName = name;
          userEmail = email;
        };

        accounts = accounts;
      };
    };
}
