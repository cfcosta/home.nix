{ pkgs, ... }:
{
  config = {
    fonts.packages = pkgs.dusk.fonts;
  };
}
