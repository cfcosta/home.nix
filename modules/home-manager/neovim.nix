{ config, pkgs, ... }: {
  home.sessionVariables = { EDITOR = "nvim"; };

  programs.neovim = {
    enable = true;
    extraConfig = builtins.readFile ../../templates/neovim/init.vim;

    plugins = with pkgs.vimPlugins; [
      fugitive
      vim-surround
      neovim-sensible
      vim-nix
      dracula-vim
      nvim-treesitter
      nvim-tree-lua
      nvim-web-devicons
      auto-pairs
      nvim-comment
      telescope-nvim
      plenary-nvim
      neogit
    ];
  };
}
