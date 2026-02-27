{ pkgs, ... }:
{
  config.environment = {
    systemPackages = with pkgs; [
      playwright
      playwright-driver.browsers
    ];

    sessionVariables = {
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04";
    };
  };
}
