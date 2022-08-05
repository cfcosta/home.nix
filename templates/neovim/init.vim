set termguicolors
colorscheme dracula
set ts=2 sts=2 sw=2 expandtab

lua << EOF
  vim.defer_fn(function()
    local opts = { noremap=true, silent=true }

    require("nvim-tree").setup()
    require("nvim_comment").setup()

    vim.keymap.set('n', '<space><space>', ':Telescope find_files<cr>', opts)
    vim.keymap.set('n', '<space>/', ':Telescope live_grep<cr>', opts)
    vim.keymap.set('n', '<space>bb', ':Telescope buffers<cr>', opts)
    vim.keymap.set('n', '<space>op', ':NvimTreeToggle<cr>', opts)
    vim.keymap.set('n', '<space>gg', ':Neogit<cr>', opts)

    vim.keymap.set('n', '<space>wv', ':vsp<cr>', opts)
    vim.keymap.set('n', '<space>ws', ':sp<cr>', opts)
    vim.keymap.set('n', '<space>wc', ':close<cr>', opts)
  end, 100)
EOF
