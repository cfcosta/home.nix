require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "bash",
    "c",
    "cpp",
    "dockerfile",
    "go",
    "haskell",
    "help",
    "javascript",
    "json",
    "lua",
    "markdown",
    "nix",
    "org",
    "rust",
    "solidity",
    "typescript",
    "yaml"
  },

  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  }
}
