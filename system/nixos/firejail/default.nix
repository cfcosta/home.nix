{ pkgs, lib, ... }:
{
  jail =
    {
      name,
      executable,
      profile ? null,
      desktop ? null,
    }:
    let
      args = lib.escapeShellArgs (lib.optional (profile != null) "--profile=${profile}");
      local = pkgs.writeTextFile "${name}.local" ''
        # fix fcitx5
        dbus-user filter
        dbus-user.talk org.freedesktop.portal.Fcitx
        ignore dbus-user none
      '';
    in
    pkgs.stdenv.mkDerivation {
      name = "${name}-firejail-wrapped";
      buildInputs = [ pkgs.firejail ];

      installPhase = ''
        mkdir -p $out/bin

        # Create the wrapper script
        cat > $out/bin/${name} << EOF
        #! ${pkgs.runtimeShell}
        exec ${pkgs.firejail}/bin/firejail ${args} -- ${executable} "\$@"
        EOF
        chmod +x $out/bin/${name}

        mkdir -p $out/etc/firejail
        cp ${local}/${name}.local $out/etc/firejail/${name}.local

        ${lib.optionalString (desktop != null) ''
          # Copy and modify the .desktop file
          mkdir -p $out/share/applications
          cp ${desktop} $out/share/applications/
          sed -i 's|Exec=${executable}|Exec=${name}|g' $out/share/applications/$(basename ${desktop})
        ''}
      '';
    };
}
