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
vim.keymap.set("n", "gd", function()
  vim.lsp.buf.definition({ loclist = true })
end, { desc = "Go to definition" })

-- Popups you jump INTO (to scroll/read), with `q` to close. <C-o> also works
-- to leave (winfixbuf is cleared on floats above). `q` is mapped buffer-local
-- on the focused popup only, so it never affects other floats (Telescope etc.).
-- The focus + dim machinery lives in util.focus_float, shared with the gitsigns
-- blame popup so hover and blame behave identically.
local focus_float = require("util.focus_float")
local focus_popup = focus_float.focus_popup

-- K / <leader>k: hover, then jump into the popup (mirrors helix <space>k).
-- hover is async, so instead of a fixed delay we poll briefly and focus the
-- instant the float exists -- snappy for fast servers, still works for slow
-- ones. The source buffer is dimmed while the popup is up, restored on close.
local function hover_focus()
  local src_buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf.hover()
  -- ~50 * 16ms ≈ 0.8s ceiling; focuses on the first tick the float is ready.
  focus_float.focus_when_ready(src_buf, function()
    return vim.b[src_buf].lsp_floating_preview
  end, 50)
end
vim.keymap.set("n", "K", hover_focus, { desc = "Hover (enter popup)" })
vim.keymap.set("n", "<leader>k", hover_focus, { desc = "Hover (enter popup)" })

-- <leader>d / <leader>D are telescope diagnostics pickers, defined in
-- plugin_config/telescope.lua. (Line-stepping stays here: Ld / Hd below.)

-- <leader>ld: hover the diagnostic in a float and jump into it. open_float is
-- line-scoped and silently does nothing off a diagnostic, so fall back to the
-- nearest diagnostic (wrapping) -- as long as the buffer has one, this surfaces
-- it. q / <C-o> close the popup (focus_popup wires those).
vim.keymap.set("n", "<leader>ld", function()
  local fbuf, fwin = vim.diagnostic.open_float()
  if not fwin then
    vim.diagnostic.jump({ count = 1, wrap = true })
    fbuf, fwin = vim.diagnostic.open_float()
  end
  focus_popup(fwin or (fbuf and vim.fn.bufwinid(fbuf)) or nil)
end, { desc = "Diagnostic hover (enter popup)" })

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

-- <leader>rl: restart LSP and refresh every buffer from disk. Stops all active
-- clients (they re-attach when buffers reload via the vim.lsp.enable FileType
-- autocmds), pulls external changes, and reloads each unmodified, file-backed
-- buffer so syntax/LSP re-initialise. Modified buffers are skipped so unsaved
-- edits are never clobbered. Copilot runs as an LSP client too, so stopping
-- everything kills it; copilot.lua won't restart its server on its own, so we
-- explicitly re-enable and re-attach it below.
local function restart_lsp()
  for _, client in ipairs(vim.lsp.get_clients()) do
    vim.lsp.stop_client(client.id, true)
  end

  -- Give clients a moment to exit before reloading + re-attaching.
  vim.defer_fn(function()
    vim.cmd("checktime") -- pull in external changes (like a manual :e)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.api.nvim_buf_is_loaded(buf)
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_get_name(buf) ~= ""
      then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("edit")
        end)
      end
    end

    -- Re-enable Copilot: enable() re-runs the client setup (its server was
    -- killed by the stop_client loop), then force-attach the current buffer.
    -- pcall keeps the restart working even if copilot isn't loaded.
    pcall(function()
      local copilot = require("copilot.command")
      copilot.enable()
      copilot.attach({ force = true })
    end)

    vim.notify("LSP + Copilot restarted; buffers refreshed", vim.log.levels.INFO)
  end, 200)
end
vim.keymap.set("n", "<leader>rl", restart_lsp, { desc = "Restart LSP + refresh buffers" })

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
