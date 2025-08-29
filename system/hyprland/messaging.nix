{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      element-desktop
      telegram-desktop
    ];

    services = {
      flatpak = {
        enable = true;

        packages = [ "org.gnome.Fractal" ];

        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
      };
    };
  };
}
