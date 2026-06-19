------------------
--
--
-- csvview (hat0uma/csvview.nvim)
--
--
------------------

-- Aligns CSV/TSV columns directly in the buffer so delimited data is readable
-- without leaving the file. Toggle with <leader>cv. Two render styles:
--   "highlight" -- just colorizes delimiters (cheapest, default here)
--   "border"    -- draws vertical │ separators between columns (table-like)
-- Field motions/text-objects are only wired while a view is active.

require("csvview").setup({
  parser = {
    -- Treat #/// lines as comments so they aren't parsed as data rows.
    comments = { "#", "//" },
  },
  view = {
    display_mode = "border",
  },
  keymaps = {
    -- if/af: inner/outer field text objects (operator + visual).
    textobject_field_inner = { "if", mode = { "o", "x" } },
    textobject_field_outer = { "af", mode = { "o", "x" } },
    -- Tab / Shift-Tab: jump between field ends (only active in a CSV view).
    jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
    jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
  },
})

vim.keymap.set("n", "<leader>cv", "<cmd>CsvViewToggle<cr>", { desc = "Toggle CSV view" })
