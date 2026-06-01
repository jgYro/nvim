------------------
--
--
-- flash (folke/flash.nvim)
--
--
------------------

-- Label-based motion. The `s` jump mirrors Emacs avy-goto-char-timer (bound
-- to M-; in .emacs): type one or more characters, every match gets a label,
-- press the label to jump. flash shows labels live as you type rather than
-- after a timer, but the workflow is the same.
--
-- All flash modes are enabled:
--   * char   mode (default on) -> f / F / t / T / ; / , get jump labels
--   * search mode (opt-in)     -> / and ? get jump labels while searching
require("flash").setup({
  modes = {
    -- Not on by default; turn it on so regular search shows flash labels.
    search = { enabled = true },
    -- char is enabled by default (f/F/t/T/;/,); left as-is.
  },
})

-- s -> flash jump, in normal, visual, and operator-pending modes (so it
-- works as a motion too, e.g. d s <label>). This replaces the built-in `s`
-- (substitute), same as the avy binding replaces self-insert.
vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })

-- By default FlashLabel links to Substitute, which oh-lucy renders as a
-- muted pink with dim text -> the jump labels are very hard to read. Force a
-- deliberately clashing, maximum-contrast label (black on bright yellow)
-- that pops against oh-lucy's dark background. Re-applied on every
-- ColorScheme load so it survives the initial theme load and theme switches.
local function set_flash_hl()
  vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#000000", bg = "#ffff00", bold = true })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("flash_label_hl", { clear = true }),
  callback = set_flash_hl,
})
set_flash_hl()
