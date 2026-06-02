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

-- Neovim pins LSP hover / signature / doc floats with winfixbuf=true, so
-- <C-o> (jumplist) inside a focused popup errors with E1513. Clear winfixbuf
-- on any floating window we enter so navigation works there.
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("clear_float_winfixbuf", { clear = true }),
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.wo[win].winfixbuf = false
    end
  end,
})

-- Extra keymaps on top of Neovim's LSP defaults (grn/gra/grr/gri/grt/gO, K,
-- <C-]>, <C-s>, [d/]d). In markdown buffers markdown-plus rebinds gd to
-- "follow TOC link" (buffer-local), which correctly wins there.
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

-- Popups you jump INTO (to scroll/read), with `q` to close. <C-o> also works
-- to leave (winfixbuf is cleared on floats above). `q` is mapped buffer-local
-- on the focused popup only, so it never affects other floats (Telescope etc.).
local function focus_popup(win)
  if not (win and win > 0 and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.api.nvim_set_current_win(win)
  vim.wo[win].winfixbuf = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = vim.api.nvim_win_get_buf(win),
    nowait = true,
    desc = "Close popup",
  })
end

-- K / <leader>k: hover, then jump into the popup (mirrors helix <space>k).
-- hover is async, so focus on a short delay; pressing again also focuses
-- (Neovim's built-in behaviour) if the server was slow.
local function hover_focus()
  vim.lsp.buf.hover()
  vim.defer_fn(function()
    focus_popup(vim.b[vim.api.nvim_get_current_buf()].lsp_floating_preview)
  end, 150)
end
vim.keymap.set("n", "K", hover_focus, { desc = "Hover (enter popup)" })
vim.keymap.set("n", "<leader>k", hover_focus, { desc = "Hover (enter popup)" })

-- <leader>d: open the diagnostic float and jump into it (synchronous).
vim.keymap.set("n", "<leader>d", function()
  local fbuf, fwin = vim.diagnostic.open_float()
  focus_popup(fwin or (fbuf and vim.fn.bufwinid(fbuf)) or nil)
end, { desc = "Diagnostic (enter popup)" })

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
