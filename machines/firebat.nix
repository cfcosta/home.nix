{
  config = {
    dusk = {
      terminal = {
        font-family = "Berkeley Mono NerdFont Mono";
        font-size = 16;
      };

      system = {
        hostname = "firebat";

        zed = {
          buffer_font_family = "Berkeley Mono NerdFont Mono";
          buffer_font_size = "Berkeley Mono NerdFont Mono";
          ui_font_family = "Berkeley Mono NerdFont Mono";
          ui_font_size = "Berkeley Mono NerdFont Mono";
        };

      };

      shell.tmux.showBattery = false;
    };
  };
}
