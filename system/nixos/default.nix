{
  config,
  flavor,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dusk) username initialPassword;
  inherit (config.dusk.system) locale timezone;
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    mkOption
    optionals
    types
    ;

  default = flavor == "nixos";
  cfg = config.dusk.system.nixos;
  nvidiaEnabled = config.dusk.system.nixos.nvidia.enable;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.determinate.nixosModules.default
    inputs.home-manager.nixosModules.default
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.nix-gaming.nixosModules.pipewireLowLatency

    ../hyprland
    ./boot.nix
    ./networking.nix
    ./nvidia.nix
    ./sudo.nix
    ./virtualisation.nix
  ];

  options.dusk.system.nixos = {
    enable = mkOption {
      inherit default;

      type = types.bool;
      description = "Whether or not to enable NixOS Modules";
    };

    createUser = mkOption {
      inherit default;

      type = types.bool;
      description = "Whether or not to create the main user";
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "thunderbolt"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];

    catppuccin = {
      enable = true;
      autoEnable = true;
    };

    environment = {
      defaultPackages = mkForce [ ];
      systemPackages =
        with pkgs;
        [
          bubblewrap
          exfatprogs
          killall
        ]
        ++ optionals nvidiaEnabled [ docbert-cuda ]
        ++ optionals (!nvidiaEnabled) [ docbert ];
    };

    hardware = {
      bluetooth.enable = true;
      graphics.enable = true;
    };

    i18n = {
      defaultLocale = locale;

      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };

      inputMethod = {
        enable = true;
        type = "fcitx5";
      };
    };

    time.timeZone = timezone;

    services = {
      eternal-terminal.enable = true;
      printing.enable = mkForce false;

      # Cap the systemd journal so it can't fill the root filesystem.
      journald.extraConfig = "SystemMaxUse=200M";

      openssh = {
        enable = true;

        settings = {
          PermitRootLogin = mkForce "no";
          PasswordAuthentication = mkForce false;
          ChallengeResponseAuthentication = mkForce false;
          X11Forwarding = mkForce false;
          PermitUserEnvironment = mkForce false;
          AllowAgentForwarding = mkForce false;
          AllowTcpForwarding = mkForce false;
          PermitTunnel = mkForce true;
        };
      };

      pcscd.enable = true;
      pipewire.lowLatency.enable = true;

      # udev rule to support vial keyboards
      udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '';
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;

      # No smartcard/token is used on these machines. When gpg-agent (which
      # backs SSH auth via enableSSHSupport) was probed for card-backed keys,
      # scdaemon deadlocked on an internal lock and never returned, wedging the
      # agent's SSH socket -- so `ssh-add`, `ssh git@github.com`, `git push`,
      # and `jj git push` all hung indefinitely. Disabling scdaemon stops the
      # agent from ever spawning it.
      #
      # The empty string is intentional: this module renders settings as
      # `key value`, so an empty value yields the bare `disable-scdaemon` flag
      # that gpg-agent expects. A non-empty value (e.g. `true`) would render
      # `disable-scdaemon true`, which gpg-agent rejects and fails to start.
      settings.disable-scdaemon = "";
    };

    security = {
      audit = {
        enable = mkDefault true;
        rules = [ "-a exit,always -F arch=b64 -S execve" ];
      };

      # The execve rule above logs every process exec, which once grew the
      # audit log to ~300 GB. Cap it with rotation: 50 MiB/file * 2 files =
      # ~100 MiB hard ceiling regardless of how much gets logged.
      auditd = {
        enable = mkDefault true;
        settings = {
          max_log_file = 50;
          max_log_file_action = "ROTATE";
          num_logs = 2;
        };
      };

      rtkit.enable = true;
    };

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    users.users.${username} = mkIf cfg.createUser {
      inherit initialPassword;

      isNormalUser = true;
      extraGroups = [ "wheel" ];

      # Pin the uid instead of letting activation allocate it. 1000 is what the
      # allocator hands the first normal user anyway (and what battlecruiser
      # already has), so this changes nothing in practice, but it makes the uid
      # visible at evaluation time — which hyprland/moonshine.nix needs, to
      # order the streaming service after this user's user@<uid>.service.
      # Declared users are allocated before auto-assigned ones, so the
      # installer image's own `nixos` account (which declares no uid) simply
      # moves out of the way.
      uid = 1000;
    };

    system = {
      nixos.variantName = "DuskOS";

      stateVersion = "26.05";
    };
  };
}
