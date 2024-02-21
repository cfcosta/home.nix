{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dusk.home;
  macLogFile = name:
    "${config.dusk.home.folders.home}/Library/Logs/${name}.log";
in {
  config = mkIf cfg.macos.enable {
    home.file."Library/Application Support/Element/config.json".text =
      builtins.readFile ./element/config.json;

    home.packages = [ pkgs.prometheus-node-exporter ];

    launchd.agents.node-exporter = {
      enable = true;

      config = {
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Interactive";
        ProgramArguments = [
          "${pkgs.prometheus-node-exporter}/bin/node_exporter"
          "--web.listen-address=:13005"
        ];
        Label = "com.dusk.prometheus-node-exporter";
        StandardOutPath = macLogFile "node-exporter";
        StandardErrorPath = macLogFile "node-exporter";
      };
    };
  };
}
