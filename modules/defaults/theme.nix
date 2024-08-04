{ config, lib, ... }:
let
  inherit (builtins) attrNames;
  inherit (lib) mkOption types;

  themeMapping = {
    dracula = {
      bat = "Dracula";
      btop = "dracula";
      delta-pager = "Dracula";
      starship = {
        aws.style = "bold #ffb86c";
        cmd_duration.style = "bold #f1fa8c";
        directory.style = "bold #50fa7b";
        hostname.style = "bold #ff5555";
        git_branch.style = "bold #ff79c6";
        git_status.style = "bold #ff5555";
        username = {
          format = "[$user]($style) on ";
          style_user = "bold #bd93f9";
        };
        character = {
          success_symbol = "[❯](bold #50fa7b)";
          error_symbol = "[❯](bold #ff5555)";
        };
      };
    };
    gruvbox-light = {
      bat = "gruvbox-light";
      btop = "gruvbox_light";
      delta-pager = "gruvbox-light";
      starship = {
        aws.style = "bold #d65d0e";
        cmd_duration.style = "bold #d79921";
        directory.style = "bold #98971a";
        hostname.style = "bold #cc241d";
        git_branch.style = "bold #b16286";
        git_status.style = "bold #cc241d";
        username = {
          format = "[$user]($style) on ";
          style_user = "bold #689d6a";
        };
        character = {
          success_symbol = "[❯](bold #98971a)";
          error_symbol = "[❯](bold #cc241d)";
        };
      };
    };
  };

  current = themeMapping."${config.dusk.theme}";
in
{
  options.dusk.theme = mkOption {
    type = types.enum (attrNames themeMapping);
    default = "gruvbox-light";
  };

  config = {
    programs.git.delta.options.theme = current.delta-pager;
    programs.bat.config.theme = current.bat;
    programs.btop.settings.color_theme = current.btop;
    programs.starship.settings = current.starship;
  };
}
