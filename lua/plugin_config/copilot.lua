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
vim.g.copilot_nes_debounce = 500

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
      -- <leader>l (not <leader>p) so it never contends with clipboard paste.
      accept_and_goto = "<leader>l",
      accept = false,
      dismiss = "<Esc>",
    },
  },

  -- Inline ghost-text suggestions.
  suggestion = {
    enabled = true,
    auto_trigger = true, -- show suggestions automatically as you type
    keymap = {
      accept = "<C-l>",
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
