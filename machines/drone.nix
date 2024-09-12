_: {
  config = {
    dusk = {
      shell.environmentFile = "\${HOME}/dusk-env.sh";
      system.hostname = "drone";
      tmux.showBattery = true;
    };
  };
}
