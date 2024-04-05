{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk;
  kernelVersion = config.boot.kernelPackages.kernel.version;
  scripts = with pkgs; [
    (writeShellScriptBin "amd-set-performance" "echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
    (writeShellScriptBin "amd-set-powersaving" "echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor")
  ];
in
{
  options.dusk.amd.enable = mkEnableOption "AMD Config and Optimizations";

  config = mkIf cfg.enable {
    environment.systemPackages = scripts;

    # Enables the amd cpu scaling https://www.kernel.org/doc/html/latest/admin-guide/pm/amd-pstate.html
    # On recent AMD CPUs this can be more energy efficient.
    boot = mkMerge [
      (mkIf ((versionAtLeast kernelVersion "5.17") && (versionOlder kernelVersion "6.1")) {
        kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" ];
        kernelModules = [ "amd-pstate" ];
      })
      (mkIf ((versionAtLeast kernelVersion "6.1") && (versionOlder kernelVersion "6.3")) {
        kernelParams = [ "amd_pstate=passive" ];
      })
      (mkIf (versionAtLeast kernelVersion "6.3") { kernelParams = [ "amd_pstate=active" ]; })
    ];
  };
}
