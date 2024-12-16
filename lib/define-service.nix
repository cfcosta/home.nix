{
  name,

  port ? null,
  subdomain ? name,

  config ? _: {
    config.services.${name} = {
      inherit (config.dusk.system.nixos.server.${name}) enable;
      openFirewall = false;
    };
  },
}:
args:
let
  inherit (args.lib) mkIf mkOption types;

  defaultSystemdServiceConfig = {
    CapabilityBoundingSet = "";
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
    ];
  };

  cfg = args.config.dusk.system.nixos.server;
  listenPort = if port == null then args.config.services.${name}.port else port;
in
{
  imports = [ config ];

  options.dusk.system.nixos.server.${name}.enable = mkOption {
    type = types.bool;
    default = cfg.enable;
  };

  config = mkIf cfg.${name}.enable {
    services.traefik.dynamicConfigOptions.http = {
      routers.${subdomain} = {
        rule = "Host(`${subdomain}.${cfg.domain}`)";
        service = name;
        entrypoints = [ "websecure" ];
        tls = true;
        middlewares = [ "strip-prefix" ];
      };

      services.${name}.loadBalancer = {
        servers = [ { url = "http://127.0.0.1:${toString listenPort}"; } ];
        passHostHeader = true;
      };
    };

    systemd.services.${name}.serviceConfig = defaultSystemdServiceConfig;
  };
}
