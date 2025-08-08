{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.dusk.shell.zellij;
in
{
  options.dusk.shell.zellij.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Whether or not to enable the Zellij terminal multiplexer";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ zellij ];

    home-manager.users.${config.dusk.username} = _: {
      programs.zellij = {
        enable = true;
        enableBashIntegration = false;

        settings = {
          pane_frames = false;
          show_startup_tips = false;
        };
      };
    };
  };
}
