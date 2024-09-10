{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      mullvad-vpn
      tor-browser
    ];
    services.mullvad-vpn.enable = true;
  };
}
