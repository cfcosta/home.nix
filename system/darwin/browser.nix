{ config, pkgs, ... }:
let
  mkRemoteDebugBrowser =
    {
      appName,
      appPath,
      alias,
      port,
    }:
    let
      launcher = pkgs.writeShellScript "${alias}-remote-debug-launcher" ''
        if [ ! -d "${appPath}" ]; then
          echo "${appName} not found at ${appPath}" >&2
          exit 1
        fi

        if /usr/bin/pgrep -x "${appName}" >/dev/null 2>&1; then
          exec /usr/bin/open -a "${appPath}" "$@"
        fi

        exec /usr/bin/open -na "${appPath}" --args \
          --remote-debugging-port=${toString port} \
          --remote-debugging-address=127.0.0.1 \
          "$@"
      '';

      cli = pkgs.writeShellScriptBin "${alias}-remote-debug" ''
        exec ${launcher} "$@"
      '';

      app = pkgs.runCommand "${alias}-remote-debug-app" { } ''
        mkdir -p "$out/Contents/MacOS"

        cat > "$out/Contents/Info.plist" <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>English</string>
            <key>CFBundleExecutable</key>
            <string>${alias}-remote-debug</string>
            <key>CFBundleIdentifier</key>
            <string>com.cfcosta.${alias}-remote-debug</string>
            <key>CFBundleName</key>
            <string>${appName} Remote Debug</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
          </dict>
        </plist>
        EOF

        cp ${launcher} "$out/Contents/MacOS/${alias}-remote-debug"
        chmod +x "$out/Contents/MacOS/${alias}-remote-debug"
      '';
    in
    {
      inherit
        alias
        app
        appName
        cli
        port
        ;
      bundleId = "com.cfcosta.${alias}-remote-debug";
    };

  braveRemoteDebug = mkRemoteDebugBrowser {
    appName = "Brave Browser";
    appPath = "/Applications/Brave Browser.app";
    alias = "brave";
    port = 9222;
  };

  chromeRemoteDebug = mkRemoteDebugBrowser {
    appName = "Google Chrome";
    appPath = "/Applications/Google Chrome.app";
    alias = "chrome";
    port = 9223;
  };

  chromiumRemoteDebug = mkRemoteDebugBrowser {
    appName = "Chromium";
    appPath = "/Applications/Chromium.app";
    alias = "chromium";
    port = 9224;
  };
in
{
  config = {
    dusk.defaults.browser = "${braveRemoteDebug.cli}/bin/brave-remote-debug";

    home-manager.users.${config.dusk.username} =
      { lib, ... }:
      {
        home = {
          packages = [
            braveRemoteDebug.cli
            chromeRemoteDebug.cli
            chromiumRemoteDebug.cli
          ];

          file."Applications/Brave Remote Debug.app".source = braveRemoteDebug.app;
        };

        home.activation.registerBraveRemoteDebugApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
            -f "$HOME/Applications/Brave Remote Debug.app" >/dev/null 2>&1 || true
        '';

        programs.bash.shellAliases = {
          brave = "brave-remote-debug";
          chrome = "chrome-remote-debug";
          chromium = "chromium-remote-debug";
        };
      };
  };
}
