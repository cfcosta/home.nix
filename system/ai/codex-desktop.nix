# The Codex desktop app.
#
# On Linux it comes from the community repackaging of OpenAI's official Linux
# build, https://github.com/ilysenko/codex-desktop-linux, since OpenAI ships no
# Nix-installable artifact. On darwin it is the official `codex-app` cask.
{ flavor, pkgs, ... }: {
  config =
    if (flavor == "nixos") then
      { environment.systemPackages = [ pkgs.codex-desktop ]; }
    else
      {
        homebrew = {
          enable = true;
          casks = [ "codex-app" ];
        };
      };
}
