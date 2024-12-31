---@diagnostic disable: missing-fields
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
      vim.keymap.set("n", "<space>fr", "<cmd>Telescope lsp_references<CR>", { desc = "Find References" })
      vim.keymap.set("n", "<space>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Find Symbols" })
      vim.keymap.set("n", "<space>fg", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Fuzzy Find Buffer" })
      vim.keymap.set("n", "<space>rg", "<cmd>Telescope live_grep<CR>", { desc = "Live Grep in CWD" })
      vim.keymap.set("n", "<space>fd", "<cmd>Telescope diagnostics<CR>", { desc = "Find Diagnostics" })
      vim.keymap.set("n", "<space>fq", "<cmd>Telescope quickfix<CR>", { desc = "Find Quickfix" })
      vim.keymap.set("n", "<space>sp", "<cmd>Telescope spell_suggest<CR>", { desc = "Spelling Suggestion" })
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
      ---@diagnostic disable-next-line: missing-fields
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "bash", "javascript", "html" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        rainbow = {
          enable = true,
          extended_mode = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<a-n>",
            node_incremental = "<a-n>",
            scope_incremental = "<c-s>",
            node_decremental = "<a-p>",
          },
        },
      })
    end
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      messages = {
        enabled = false
      }
    },
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
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")

      mc.setup()

      local set = vim.keymap.set

      -- Add or skip cursor above/below the main cursor.
      set({ "n", "v" }, "K",
        function() mc.lineAddCursor(-1) end)
      set({ "n", "v" }, "J",
        function() mc.lineAddCursor(1) end)
      set({ "n", "v" }, "<leader>K",
        function() mc.lineSkipCursor(-1) end)
      set({ "n", "v" }, "<leader>J",
        function() mc.lineSkipCursor(1) end)

      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "v" }, "<leader>n",
        function() mc.matchAddCursor(1) end)
      set({ "n", "v" }, "<leader>s",
        function() mc.matchSkipCursor(1) end)
      set({ "n", "v" }, "<leader>N",
        function() mc.matchAddCursor(-1) end)
      set({ "n", "v" }, "<leader>S",
        function() mc.matchSkipCursor(-1) end)

      -- Add all matches in the document
      set({ "n", "v" }, "<leader>A", mc.matchAllAddCursors)

      -- You can also add cursors with any motion you prefer:
      -- set("n", "<right>", function()
      --     mc.addCursor("w")
      -- end)
      -- set("n", "<leader><right>", function()
      --     mc.skipCursor("w")
      -- end)

      -- Rotate the main cursor.
      set({ "n", "v" }, "<leader>l", mc.nextCursor)
      set({ "n", "v" }, "<leader>h", mc.prevCursor)

      -- Delete the main cursor.
      set({ "n", "v" }, "<leader>x", mc.deleteCursor)

      -- Add and remove cursors with control + left click.
      set("n", "<c-leftmouse>", mc.handleMouse)

      -- Easy way to add and remove cursors using the main cursor.
      set({ "n", "v" }, "<c-q>", mc.toggleCursor)

      -- Clone every cursor and disable the originals.
      set({ "n", "v" }, "<leader><c-q>", mc.duplicateCursors)

      set("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        elseif mc.hasCursors() then
          mc.clearCursors()
        else
          -- Default <esc> handler.
        end
      end)

      -- bring back cursors if you accidentally clear them
      set("n", "<leader>gv", mc.restoreCursors)

      -- Align cursor columns.
      set("n", "<leader>a", mc.alignCursors)

      -- Split visual selections by regex.
      set("v", "S", mc.splitCursors)

      -- Append/insert for each line of visual selections.
      set("v", "I", mc.insertVisual)
      set("v", "A", mc.appendVisual)

      -- match new cursors within visual selections by regex.
      set("v", "M", mc.matchCursors)

      -- Rotate visual selection contents.
      set("v", "<leader>t",
        function() mc.transposeCursors(1) end)
      set("v", "<leader>T",
        function() mc.transposeCursors(-1) end)

      -- Jumplist support
      set({ "v", "n" }, "<c-i>", mc.jumpForward)
      set({ "v", "n" }, "<c-o>", mc.jumpBackward)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { link = "Cursor" })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end
  }
})
