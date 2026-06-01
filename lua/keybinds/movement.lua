------------------
--
--
-- Movement Keybinds
--
--
------------------

-- Helix-style line motions: gh -> first non-blank char, gl -> end of line.
-- Mapped in normal and visual so they work as both motions and selections.
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Keep the cursor centered while scrolling and searching, so context never
-- jumps to the screen edge. n/N also reopen any folds (zv) on the match.
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
