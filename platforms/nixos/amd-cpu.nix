{ config, lib, pkgs, dusk, ... }:
with lib;
let kernelVersion = config.boot.kernelPackages.kernel.version;
in {
  dusk.options.modules.amd-cpu = { };

  config = {
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.amd.updateMicrocode = true;

    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "amd-set-performance"
        "echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
      (writeShellScriptBin "amd-set-powersaving"
        "echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
    ];

    # Enables the amd cpu scaling https://www.kernel.org/doc/html/latest/admin-guide/pm/amd-pstate.html
    # On recent AMD CPUs this can be more energy efficient.
    boot = mkMerge [
      (mkIf ((versionAtLeast kernelVersion "5.17")
        && (versionOlder kernelVersion "6.1")) {
          kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" ];
          kernelModules = [ "amd-pstate" "kvm-amd" ];
        })
      (mkIf ((versionAtLeast kernelVersion "6.1")
        && (versionOlder kernelVersion "6.3")) {
          kernelParams = [ "amd_pstate=passive" "kvm-amd" ];
        })
      (mkIf (versionAtLeast kernelVersion "6.3") {
        kernelParams = [ "amd_pstate=active" "kvm-amd" ];
      })
    ];
  };
}
