{
  pkgs,
  config,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      virt-manager
      docker-compose
      podman-compose
      ctop
      (pkgs.callPackage ./waydroid pkgs)
    ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };

      libvirtd.enable = true;
      lxd.enable = true;

      podman = {
        enable = true;
        autoPrune.enable = true;
      };

      waydroid.enable = true;
    };

    users.users.${config.dusk.username}.extraGroups = [
      "docker"
      "libvirtd"
      "lxd"
      "podman"
    ];
  };
}
