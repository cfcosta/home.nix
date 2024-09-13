{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) concatLines mkIf optionals;
  inherit (pkgs) runCommand;

  wrapIcons =
    packages:
    runCommand "firejail-icons"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        meta.priority = -1;
      }
      ''
        mkdir -p "$out/share/icons"
        ${concatLines (
          map (pkg: ''
            tar -C "${pkg}" -c share/icons -h --mode 0755 -f - | tar -C "$out" -xf -
          '') packages
        )}
        find "$out/" -type f -print0 | xargs -0 chmod 0444
        find "$out/" -type d -print0 | xargs -0 chmod 0555
      '';
in
{

  jail =
    {
      name,
      executable,
      profile ? null,
      desktop ? null,
      graphical ? false,
    }:
    let
      desktopEnabled = config.dusk.system.nixos.desktop.enable;
    in
    mkIf (!graphical || desktopEnabled) {
      environment = {
        etc."firejail/${name}.local".text = ''
          # fix fcitx5
          dbus-user filter
          dbus-user.talk org.freedesktop.portal.Fcitx
          ignore dbus-user none
        '';

        systemPackages = optionals (desktopEnabled && desktop != null) [
          (wrapIcons [ pkgs.${name} ])
        ];
      };

      programs.firejail.wrappedBinaries.${name} = {
        inherit desktop executable;

        profile = "${pkgs.firejail}/etc/firejail/${profile}";
      };
    };
}
