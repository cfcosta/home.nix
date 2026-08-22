{ pkgs, ... }: {
  config = {
    networking.resolvconf.extraConfig = ''
      name_servers_append="1.1.1.1 1.0.0.1"
      resolv_conf_options="edns0 timeout:1 attempts:2"
    '';

    services.tailscale.extraSetFlags = [ "--accept-dns=false" ];

    networking.networkmanager = {
      ethernet.macAddress = "permanent";
      wifi.scanRandMacAddress = false;

      # Re-apply the Intel I225-V workarounds whenever NetworkManager brings
      # the link up. This NIC can silently stop passing traffic after hours of
      # uptime when Energy Efficient Ethernet/offloads are left enabled.
      dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "eno1-link-workarounds" ''
            if [ "$1" = "eno1" ] && [ "$2" = "up" ]; then
              ${pkgs.ethtool}/bin/ethtool --set-eee eno1 eee off || true
              ${pkgs.ethtool}/bin/ethtool -K eno1 tso off gso off gro off || true
            fi
          '';
        }
      ];
    };
  };
}
