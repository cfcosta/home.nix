_:
let
  inherit (builtins) readFile;
in
{
  config.programs.tmux = {
    enable = true;

    escapeTime = 0;
    keyMode = "vi";
    terminal = "xterm-256color";
    extraConfig = readFile ./config;
  };
}
