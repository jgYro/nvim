------------------
--
--
-- Plugin Imports (vim.pack)
--
--
------------------

-- vim.pack only clones/loads the repos listed here. Per-plugin
-- configuration lives in lua/plugin_config/<name>.lua and is
-- loaded after the corresponding repo is on the runtimepath.
--
-- Order matters: list dependencies before the plugin that needs
-- them so they are available when that plugin's setup runs.

vim.pack.add({
  -- (optional) copilot-lsp, for Copilot NES (Next Edit Suggestions).
  -- Listed first so it is on the runtimepath when copilot.lua sets up.
  { src = "https://github.com/copilotlsp-nvim/copilot-lsp" },
  -- Copilot
  { src = "https://github.com/zbirenbaum/copilot.lua" },
  -- Markdown editing enhancements (zero dependencies)
  { src = "https://github.com/YousefHadder/markdown-plus.nvim" },
  -- which-key: popup of available keybinds following a prefix
  { src = "https://github.com/folke/which-key.nvim" },
  -- plenary: Lua utility library. Required dependency of telescope; listed
  -- first so it is on the runtimepath when telescope sets up.
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  -- Telescope: fuzzy finder over files, grep, buffers, etc.
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  -- Harpoon (v1): the original, now-deprecated version, pinned to the
  -- master branch by preference (harpoon2 lives on a separate branch).
  -- Also depends on plenary.nvim, already listed above.
  { src = "https://github.com/theprimeagen/harpoon", version = "master" },
  -- flash: label-based motion (used only for its jump, bound to `s`).
  { src = "https://github.com/folke/flash.nvim" },
  -- oh-lucy: colorscheme.
  { src = "https://github.com/Yazeed1s/oh-lucy.nvim" },
})

--
-- Per-plugin configuration
--
require("plugin_config.copilot")
require("plugin_config.markdown-plus")
require("plugin_config.which-key")
require("plugin_config.telescope")
require("plugin_config.harpoon")
require("plugin_config.flash")
-- Colorscheme last, so it themes everything loaded above.
require("plugin_config.oh-lucy")
