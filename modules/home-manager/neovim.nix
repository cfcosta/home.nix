{ config, pkgs, ... }: {
  home.sessionVariables = { EDITOR = "nvim"; };

  home.packages = with pkgs; [
    sumneko-lua-language-server
    tree-sitter
    clang
    neovide # TODO: Do a global graphical flag to install those, use same flag as emacs
  ];

  programs.neovim.enable = true;

  xdg.configFile."nvim" = {
    source = ../../templates/neovim;
    recursive = true;
  };

  home.file.nvim-packer = {
    target = ".local/share/nvim/site/pack/packer/start/packer.nvim";

    source = pkgs.fetchFromGitHub {
      owner = "wbthomason";
      repo = "packer.nvim";
      rev = "master";
      sha256 = "sha256-IIokssVOGFf5/pZQ4gRCPV5ktWPDfCCKJb5Ux1DrKok=";
    };
  };
}
