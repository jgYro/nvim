-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Define leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Install plugins
require("lazy").setup({
  -- Lazy
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
    config = function()
      local one = require("onedarkpro")
      one.setup({
        colors = {
          float_bg = "require('onedarkpro.helpers').lighten('bg', 10, 'onedark_dark')",
        },
        highlights = {
          NormalFloat = { bg = "${float_bg}" },
          Comment = { italic = true },
          Directory = { bold = true },
          ErrorMsg = { italic = true, bold = true }
        },
        styles = {
          types = "NONE",
          methods = "NONE",
          numbers = "NONE",
          strings = "NONE",
          comments = "italic",
          keywords = "bold,italic",
          constants = "NONE",
          functions = "italic",
          operators = "NONE",
          variables = "NONE",
          parameters = "NONE",
          conditionals = "italic",
          virtual_text = "NONE",
        }
      })
      vim.cmd("colorscheme onedark_dark")
    end
  },
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = '*',
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    opts_extend = { "sources.default" }
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      vim.keymap.set("n", "<space>ff", "<cmd>Telescope find_files<CR>", { desc = "Find Files" })
      vim.keymap.set("n", "<space>fd", "<cmd>Telescope diagnostics<CR>", { desc = "Find Diagnostics" })
      vim.keymap.set("n", "<space>fq", "<cmd>Telescope quickfix<CR>", { desc = "Find Quickfix" })
      -- This is your opts table
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }

          }
        }
      }
      -- To get ui-select loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require("telescope").load_extension("ui-select")
    end
  },
  {
    'ThePrimeagen/harpoon',
    config = function()
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")

      vim.keymap.set("n", "<leader><leader>a", mark.add_file)
      vim.keymap.set("n", "<leader><leader>e", ui.toggle_quick_menu)

      vim.keymap.set("n", "<leader><leader>h", function()
        ui.nav_file(1)
      end)
      vim.keymap.set("n", "<leader><leader>j", function()
        ui.nav_file(2)
      end)
      vim.keymap.set("n", "<leader><leader>k", function()
        ui.nav_file(3)
      end)
      vim.keymap.set("n", "<leader><leader>l", function()
        ui.nav_file(4)
      end)
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "bash", "javascript", "html" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    }
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          inlay_hints = {
            enabled = true
          },
          library = {
            {
              path = "${3rd}/luv/library", words = { "vim%.uv" }
            },
          }
        }
      }
    },
    config = function()
      local lspconfig = require('lspconfig')
      lspconfig.rust_analyzer.setup {
        filetypes = { "rust" },
        on_attach = function(client, bufnr)
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end,
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true
            },
            checkOnSave = {
              command = "clippy"
            },
          },
          inlayHints = {
            bindingModeHints = {
              enable = false,
            },
            chainingHints = {
              enable = true,
            },
            closingBraceHints = {
              enable = true,
              minLines = 25,
            },
            closureReturnTypeHints = {
              enable = "never",
            },
            lifetimeElisionHints = {
              enable = "never",
              useParameterNames = false,
            },
            maxLength = 25,
            parameterHints = {
              enable = true,
            },
            reborrowHints = {
              enable = "never",
            },
            renderColons = true,
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },
        },
      }
      lspconfig.lua_ls.setup {
        settings = {
          Lua = {},
        },
      }
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
  }
})
