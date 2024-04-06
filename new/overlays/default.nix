final: prev: {
  dusk-os = {
    mkUser =
      {
        name,
        user,
        email,
        accounts ? { },
      }:
      {
        dusk-os.users.${user} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      };
  };
}
