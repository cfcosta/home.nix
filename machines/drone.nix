{
  dusk = {
    hostname = "drone";
    shell.environmentFile = "\${HOME}/dusk-env.sh";
    tmux.showBattery = true;
  };
}
