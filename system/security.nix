{ config, ... }: {
  config = {
    home-manager.users.${config.dusk.username} = _: {
      home.file = {
        ".npmrc".text = ''
          min-release-age=7
          minimum-release-age=10080
          save-exact=true
          ignore-scripts=true
        '';

        ".bunfig.toml".text = ''
          [install]
          minimumReleaseAge = 604800
          ignoreScripts = true
        '';
      };

      programs.git.settings.core.hooksPath = "/dev/null";
    };
  };
}
