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
    -- <C-y> accept top · <C-n>/<C-p> select · <C-space> menu/docs · <C-e> hide.
    preset = "default",
    -- Enter accepts the selected item, else falls through to a normal newline.
    ["<CR>"] = { "accept", "fallback" },
    -- Leave <C-k> to copilot (previous suggestion). Signature help is still
    -- available on the native <C-s> insert-mode mapping.
    ["<C-k>"] = { "fallback" },
  },
  -- Don't auto-highlight the first item (Helix-style): so Enter only accepts
  -- an item you've explicitly selected and otherwise inserts a newline.
  completion = { list = { selection = { preselect = false } } },
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
  -- Linters (also LSP servers), running alongside the above:
  "eslint", -- JS/TS
  "ruff", -- Python (with pyright)
  "golangci_lint_ls", -- Go (with gopls)
})

-- Extra keymaps on top of Neovim's LSP defaults (grn/gra/grr/gri/grt/gO, K,
-- <C-]>, <C-s>, [d/]d). In markdown buffers markdown-plus rebinds gd to
-- "follow TOC link" (buffer-local), which correctly wins there.
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
-- <leader>k = hover docs (mirrors helix's <space>k).
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover documentation" })

-- Step through diagnostics, matching the Lq/Hq quickfix idiom. on_jump opens
-- the float after moving (the old `float = true` option is deprecated).
local function diag_jump(count)
  vim.diagnostic.jump({
    count = count,
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({ bufnr = bufnr })
    end,
  })
end
vim.keymap.set("n", "Ld", function()
  diag_jump(1)
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "Hd", function()
  diag_jump(-1)
end, { desc = "Prev diagnostic" })

-- Diagnostics (native).
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  -- "if_many" only prefixes the source when a line has diagnostics from more
  -- than one source -- avoids the doubled "errcheck: errcheck:" you get when a
  -- linter (golangci-lint) already bakes its name into the message.
  float = { border = "rounded", source = "if_many" },
})
