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
        'ryanoasis/vim-devicons'
      },
      config = function()
        vim.keymap.set('n', '<space>op', ':NvimTreeToggle<cr>', opts)
      end
    }

    use {
      'TimUntersberger/neogit',
      requires = {
        'nvim-lua/plenary.nvim',
        'sindrets/diffview.nvim'
      },
      config = function()
        vim.keymap.set('n', '<space>gg', ':Neogit<cr>', opts)
        local neogit = require("neogit")

        neogit.setup({
          use_magit_keybindings = true,
          integrations = {
            diffview = true
          }
        })
      end
    }

    use({
        'dracula/vim',
        as = 'dracula',
        config = function()
          vim.cmd('colorscheme dracula')
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

    use({
      "windwp/nvim-autopairs",
      config = function() require("nvim-autopairs").setup {} end
    })

    use("direnv/direnv.vim")
    use("github/copilot.vim")
    use('jeffkreeftmeijer/neovim-sensible')
    use({
      'kylechui/nvim-surround',
      config = function()
        require("nvim-surround").setup({})
      end
    })
    use('mbbill/undotree')
    use('nvim-treesitter/playground')
    use({'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'})
    use('terrortylor/nvim-comment')
    use('tpope/vim-fugitive')
    use({
      'sbdchd/neoformat',
      config = function()
        vim.cmd([[
        augroup fmt
          autocmd!
          autocmd BufWritePre * undojoin | Neoformat
        augroup END
        ]])
      end
  })
end)
