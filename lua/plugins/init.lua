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
  -- dressing: floating UI for vim.ui.input / vim.ui.select (used by the
  -- llm_yank prompt, code actions, rename, etc.).
  { src = "https://github.com/stevearc/dressing.nvim" },
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
  -- Treesitter (main branch / the rewrite). Listed before the plugins that
  -- build on it. main branch needs :TSUpdate after the plugin updates; that
  -- is wired via a PackChanged autocmd in plugin_config/treesitter.lua.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  -- Textobjects, also on the main branch.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  -- Classic module experience (highlight/indent/incremental_selection) on top
  -- of the treesitter main branch.
  { src = "https://github.com/MeanderingProgrammer/treesitter-modules.nvim" },
  -- render-markdown: in-buffer rendering of markdown (headings, code blocks,
  -- tables, checkboxes), powered by treesitter.
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  -- blink.cmp: completion engine. Pinned to the v1.x tag so the prebuilt Rust
  -- fuzzy-matcher binary is downloaded (no cargo build needed).
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1") },
  -- conform: format-on-save via external formatters (stylua/prettier/ruff).
  { src = "https://github.com/stevearc/conform.nvim" },
  -- watcher: review external file changes (floating diff -> accept/reject).
  { src = "https://github.com/jgYro/watcher.nvim" },
  -- gitsigns: git change signs in the gutter (+ hunk navigation/staging).
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  -- nvim-tree: file explorer sidebar.
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  -- nvim-tree-preview: floating, scrollable file preview from the tree.
  -- Depends on plenary (listed above).
  { src = "https://github.com/b0o/nvim-tree-preview.lua" },
  -- twilight: dim everything outside the current code scope ("focus mode").
  { src = "https://github.com/folke/twilight.nvim" },
  -- yank2think: collect code selections into an LLM-ready markdown buffer.
  -- (Extracted from this config into its own plugin.)
  { src = "https://github.com/jgYro/yank2think.nvim" },
  -- oh-lucy: colorscheme.
  { src = "https://github.com/Yazeed1s/oh-lucy.nvim" },
})

--
-- Per-plugin configuration
--
require("plugin_config.copilot")
require("plugin_config.markdown-plus")
require("plugin_config.which-key")
require("plugin_config.dressing")
require("plugin_config.telescope")
require("plugin_config.harpoon")
require("plugin_config.flash")
require("plugin_config.treesitter")
require("plugin_config.render-markdown")
require("plugin_config.lsp")
require("plugin_config.conform")
-- watcher disabled for now; re-enable to restore external-change review.
-- require("plugin_config.watcher")
require("plugin_config.gitsigns")
require("plugin_config.nvim-tree")
require("plugin_config.twilight")
require("plugin_config.yank2think")
-- Colorscheme last, so it themes everything loaded above.
require("plugin_config.oh-lucy")
