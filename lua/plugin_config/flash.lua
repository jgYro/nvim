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
