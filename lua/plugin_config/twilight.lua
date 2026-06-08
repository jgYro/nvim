------------------
--
--
-- twilight (folke/twilight.nvim)
--
--
------------------

-- "Focus mode": dims everything outside the code scope around your cursor
-- (treesitter-aware -- the current function/block stays at full brightness) and
-- follows the cursor as you read. Toggle with <leader>fc. While it's on,
-- <C-S-n>/<C-S-p> (Ctrl+Shift+N/P) grow/shrink how much context stays bright.
-- (Shifted so they don't collide with <C-n>/<C-p> = move down/up.)

local twilight = require("twilight")
local tw_config = require("twilight.config")
local tw_view = require("twilight.view")

twilight.setup({
  -- context: how many lines around the cursor twilight tries to keep bright (on
  -- top of the treesitter node). This is what <C-n>/<C-p> adjust below.
  context = 10,
  treesitter = true,
})

-- Grow/shrink the focused scope by changing `context` and re-dimming live.
local CTX_STEP = 4
local CTX_MIN = 2
local CTX_MAX = 60

local function adjust_scope(delta)
  local ctx = math.max(CTX_MIN, math.min(CTX_MAX, tw_config.options.context + delta))
  tw_config.options.context = ctx
  pcall(tw_view.update) -- re-apply dimming now (pcall: buffers w/o a TS parser)
  vim.notify("Focus scope: " .. ctx .. " lines", vim.log.levels.INFO)
end

-- The scope keys only exist while focus mode is on, so <C-n>/<C-p> keep their
-- normal-mode defaults otherwise.
local function set_scope_keys(on)
  if on then
    vim.keymap.set("n", "<C-S-n>", function() adjust_scope(CTX_STEP) end, { desc = "Focus: grow scope" })
    vim.keymap.set("n", "<C-S-p>", function() adjust_scope(-CTX_STEP) end, { desc = "Focus: shrink scope" })
  else
    pcall(vim.keymap.del, "n", "<C-S-n>")
    pcall(vim.keymap.del, "n", "<C-S-p>")
  end
end

-- <leader>fc: toggle focus mode, wiring up / tearing down the scope keys.
vim.keymap.set("n", "<leader>fc", function()
  -- pcall: twilight errors on buffers without a treesitter parser; swallow it
  -- so the toggle/keymap state stays consistent either way.
  pcall(twilight.toggle)
  set_scope_keys(tw_view.enabled)
  vim.notify("Focus code: " .. (tw_view.enabled and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Focus code (twilight)" })
