{
  config,
  pkgs,
  lib,
  ...
}:
let
  berkeley-mono-nerd-font = pkgs.stdenvNoCC.mkDerivation {
    pname = "berkeley-mono-nerd-font";
    version = "0.0.0";

    src = config.age.secrets."berkeley-mono.tar.gz.age".path;

    installPhase = ''
      runHook preInstall

      install -Dm644 otf/*.otf -t $out/share/fonts/opentype
      install -Dm644 ttf/*.ttf -t $out/share/fonts/truetype

      runHook postInstall
    '';

    meta = with lib; {
      license = licenses.unfree;
    };
  };
in
{
  environment.systemPackages = [ berkeley-mono-nerd-font ];
}
