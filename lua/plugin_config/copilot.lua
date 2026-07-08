------------------
--
--
-- Copilot (zbirenbaum/copilot.lua)
--
--
------------------

-- copilot-lsp globals.
-- Packer set these in the dependency's `init` hook; vim.pack has no such
-- hook, so set them as plain globals before copilot-lsp is used.
vim.g.copilot_nes_debounce = 100

-- Resolve a Node >= 22 for the Copilot server. copilot.lua otherwise calls
-- bare `node` from PATH, which under nvm resolves to v20 (too old) and is
-- non-deterministic when nvim is launched from a GUI. We try absolute,
-- nvm-independent paths first and fall back to whatever `node` is on PATH.
local function resolve_node()
  local function major(bin)
    -- vim.fn.exists("*executable") is overkill; just probe the version.
    local out = vim.fn.system({ bin, "--version" })
    if vim.v.shell_error ~= 0 then
      return nil
    end
    return tonumber(out:match("v(%d+)%."))
  end

  local candidates = { "/opt/homebrew/bin/node" }
  -- Highest-versioned node installed under nvm, if any.
  for _, dir in ipairs(vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*"), true, true)) do
    table.insert(candidates, dir .. "/bin/node")
  end

  for _, bin in ipairs(candidates) do
    if vim.fn.executable(bin) == 1 and (major(bin) or 0) >= 22 then
      return bin
    end
  end
  return "node" -- last resort: PATH (copilot will warn if it's too old)
end

require("copilot").setup({
  -- See resolve_node() above for why this isn't just "node".
  copilot_node_command = resolve_node(),

  -- NES (Next Edit Suggestions), provided via copilotlsp-nvim/copilot-lsp.
  -- Experimental. Keymaps pass through to the original mapping when there
  -- is no pending suggestion.
  nes = {
    enabled = true,
    keymap = {
      -- <Tab> (normal mode) accepts the green suggestion and jumps to the next
      -- edit, so a cascade of edits is just Tab-Tab-Tab. copilot wraps this with
      -- passthrough: when no NES is pending, <Tab> falls back to its normal job
      -- (jumplist-forward / <C-i>), so nothing is lost. Keeping accept off <C-p>
      -- leaves <C-p> for flash repeat-back.
      accept_and_goto = "<Tab>",
      accept = false,
      dismiss = "<Esc>",
    },
  },

  -- Inline ghost-text suggestions.
  suggestion = {
    enabled = true,
    -- Don't show suggestions automatically; only on explicit request (<C-i>
    -- below, or <C-j>/<C-k> which also fire a request when none is showing).
    auto_trigger = false,
    keymap = {
      accept = false,
      accept_word = false,
      accept_line = false,
      next = "<C-j>",
      prev = "<C-k>",
      dismiss = "<C-h>",
    },
  },

  -- Suggestion panel (multiple completions in a split).
  panel = {
    enabled = true,
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>",
    },
  },
})

local function accept_copilot_suggestion()
  local bufnr = vim.api.nvim_get_current_buf()

  if vim.b[bufnr].nes_state then
    local ok, nes = pcall(require, "copilot-lsp.nes")
    if ok and nes.apply_pending_nes(bufnr) then
      nes.walk_cursor_end_edit(bufnr)
      return
    end
  end

  require("copilot.suggestion").accept()
end

vim.keymap.set("i", "<C-l>", accept_copilot_suggestion, { desc = "Copilot: accept suggestion" })

-- Explicitly request an inline suggestion (auto_trigger is off). suggestion.next()
-- fires a fresh request when nothing is showing, then cycles on repeat.
--
-- NOTE: in most terminals <C-i> and <Tab> are the same byte, so this would also
-- take over <Tab> in insert mode. Terminals speaking the kitty keyboard protocol
-- (kitty/ghostty/wezterm/foot) keep them distinct, leaving <Tab> alone. Verify
-- with `:verbose imap <C-i>` vs `:verbose imap <Tab>`.
vim.keymap.set("i", "<C-i>", function()
  require("copilot.suggestion").next()
end, { desc = "Copilot: request inline suggestion" })
