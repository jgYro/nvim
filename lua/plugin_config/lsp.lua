------------------
--
--
-- LSP (native vim.lsp) + completion (blink.cmp) + diagnostics
--
--
------------------

-- LSP is configured with the native API: server definitions live in
-- <config>/lsp/<name>.lua and are turned on with vim.lsp.enable(). Completion
-- is handled by blink.cmp, whose capabilities we advertise to every server.
-- Diagnostics use the native vim.diagnostic API.
--
-- Most LSP keymaps are Neovim defaults and are NOT redefined here:
--   grn rename · gra code action · grr references · gri implementation
--   grt type def · gO document symbols · K hover · <C-s> signature (insert)
--   [d / ]d previous / next diagnostic
-- Server binaries must be installed separately (see the note atop each
-- lsp/<name>.lua).

-- Completion engine.
require("blink.cmp").setup({
  keymap = {
    -- <C-y> accept · <C-n>/<C-p> select · <C-space> menu/docs · <C-e> hide.
    preset = "default",
    -- Leave <C-k> to copilot (previous suggestion). Signature help is still
    -- available on the native <C-s> insert-mode mapping.
    ["<C-k>"] = { "fallback" },
  },
  appearance = { nerd_font_variant = "mono" },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  -- Use the Rust fuzzy matcher (prebuilt binary via the pinned tag), falling
  -- back to the Lua implementation with a warning if it is unavailable.
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- Advertise blink's completion capabilities to every server. Per-server
-- settings live in <config>/lsp/<name>.lua and merge over this.
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- Enable the hand-written server configs (lsp/<name>.lua).
vim.lsp.enable({
  "lua_ls",
  "rust_analyzer",
  "dartls",
  "pyright",
  "gopls",
  "ts_ls",
  "html",
  "intelephense",
  "tailwindcss",
})

-- Diagnostics (native).
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})
