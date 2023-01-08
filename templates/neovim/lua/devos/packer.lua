vim.cmd.packadd("packer.nvim")

return require('packer').startup(function(use)
    use {
      'nvim-telescope/telescope.nvim', tag = '0.1.0',
      requires = { {'nvim-lua/plenary.nvim'} },
      config = function()
        vim.keymap.set('n', '<space><space>', ':Telescope find_files<cr>', opts)
        vim.keymap.set('n', '<space>/', ':Telescope live_grep<cr>', opts)
        vim.keymap.set('n', '<space>bb', ':Telescope buffers<cr>', opts)
      end
    }

    use {
      'nvim-tree/nvim-tree.lua',
      requires = {
        'nvim-tree/nvim-devicons'
      },
      config = function()
        vim.keymap.set('n', '<space>op', ':NvimTreeToggle<cr>', opts)
      end
    }

    use {
      'TimUntersberger/neogit',
      config = function()
        vim.keymap.set('n', '<space>gg', ':Neogit<cr>', opts)
      end
    }

    use({
        'shaunsingh/moonlight.nvim',
        as = 'moonlight',
        config = function()
          vim.cmd('colorscheme moonlight')
        end
    })

    use {
      'VonHeikemen/lsp-zero.nvim',

      requires = {
        -- LSP Support
        {'neovim/nvim-lspconfig'},
        {'williamboman/mason.nvim'},
        {'williamboman/mason-lspconfig.nvim'},

        -- Autocompletion
        {'hrsh7th/nvim-cmp'},
        {'hrsh7th/cmp-buffer'},
        {'hrsh7th/cmp-path'},
        {'saadparwaiz1/cmp_luasnip'},
        {'hrsh7th/cmp-nvim-lsp'},
        {'hrsh7th/cmp-nvim-lua'},

        -- Snippets
        {'L3MON4D3/LuaSnip'},
        {'rafamadriz/friendly-snippets'},
      }
    }

    use("direnv/direnv.vim")
    use("github/copilot.vim")
    use('jeffkreeftmeijer/neovim-sensible')
    use('kylechui/nvim-surround')
    use('mbbill/undotree')
    use('nvim-treesitter/playground')
    use({'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'})
    use('terrortylor/nvim-comment')
    use('tpope/vim-fugitive')
end)