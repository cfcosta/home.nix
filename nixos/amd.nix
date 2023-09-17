{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.dusk;
  kernelVersion = config.boot.kernelPackages.kernel.version;
in {
  options.dusk.amd.enable = mkEnableOption "AMD Config and Optimizations";

  config = mkIf cfg.enable {
    # Enables the amd cpu scaling https://www.kernel.org/doc/html/latest/admin-guide/pm/amd-pstate.html
    # On recent AMD CPUs this can be more energy efficient.
    boot = mkMerge [
      (mkIf ((versionAtLeast kernelVersion "5.17")
        && (versionOlder kernelVersion "6.1")) {
          kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" ];
          kernelModules = [ "amd-pstate" ];
        })
      (mkIf ((versionAtLeast kernelVersion "6.1")
        && (versionOlder kernelVersion "6.3")) {
          kernelParams = [ "amd_pstate=passive" ];
        })
      (mkIf (versionAtLeast kernelVersion "6.3") {
        kernelParams = [ "amd_pstate=active" ];
      })
    ];
  };
}
