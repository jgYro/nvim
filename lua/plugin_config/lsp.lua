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

-- While reading a hover popup, grey out the code behind it so the docs stand
-- out. We lay a single buffer-wide extmark in a high priority (above treesitter)
-- that recolours every token to a muted grey, and clear it when the float
-- closes. The dim highlight is refreshed on :colorscheme.
local dim_ns = vim.api.nvim_create_namespace("lsp_hover_dim")
local dimmed_buf = nil

local function set_hover_dim_hl()
  vim.api.nvim_set_hl(0, "LspHoverDim", { fg = "#3b3e48" })
end
set_hover_dim_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("lsp_hover_dim_hl", { clear = true }),
  callback = set_hover_dim_hl,
})

local function undim_hover()
  if dimmed_buf and vim.api.nvim_buf_is_valid(dimmed_buf) then
    vim.api.nvim_buf_clear_namespace(dimmed_buf, dim_ns, 0, -1)
  end
  dimmed_buf = nil
end

local function dim_hover(buf)
  undim_hover()
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local last_line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""
  vim.api.nvim_buf_set_extmark(buf, dim_ns, 0, 0, {
    end_row = last,
    end_col = #last_line,
    hl_group = "LspHoverDim",
    hl_eol = true,
    priority = 10000,
  })
  dimmed_buf = buf
end

-- K / <leader>k: hover, then jump into the popup (mirrors helix <space>k).
-- hover is async, so instead of a fixed delay we poll briefly and focus the
-- instant the float exists -- snappy for fast servers, still works for slow
-- ones. The source buffer is dimmed while the popup is up, restored on close.
local function focus_hover_when_ready(src_buf, tries)
  local win = vim.b[src_buf].lsp_floating_preview
  if win and vim.api.nvim_win_is_valid(win) then
    dim_hover(src_buf)
    focus_popup(win)
    -- Undim as soon as the hover float closes (q, cursor move, <C-o> away).
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = undim_hover,
    })
  elseif tries > 0 then
    vim.defer_fn(function()
      focus_hover_when_ready(src_buf, tries - 1)
    end, 16)
  end
end

local function hover_focus()
  local src_buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf.hover()
  -- ~50 * 16ms ≈ 0.8s ceiling; focuses on the first tick the float is ready.
  focus_hover_when_ready(src_buf, 50)
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

-- <leader>rl: restart LSP and refresh every buffer from disk. Stops all active
-- clients (they re-attach when buffers reload via the vim.lsp.enable FileType
-- autocmds), pulls external changes, and reloads each unmodified, file-backed
-- buffer so syntax/LSP re-initialise. Modified buffers are skipped so unsaved
-- edits are never clobbered.
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
    vim.notify("LSP restarted; buffers refreshed", vim.log.levels.INFO)
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
