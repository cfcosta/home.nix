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
        home.stateVersion = "24.05";
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        programs.git = {
          enable = true;
          userName = name;
          userEmail = email;
        };
      };

      accounts = accounts;
    };
}
