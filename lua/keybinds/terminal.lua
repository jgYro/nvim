------------------
--
--
-- Terminal Keybinds
--
--
------------------

-- NOTE: terminal lives on <Space>u (not <Space>t) so it doesn't collide
-- with markdown-plus's table prefix (<Space>t...) in markdown buffers.

local floating_terminal = require("util.floating_terminal")

-- Open a terminal in a vertical split on the right, in insert mode.
vim.keymap.set("n", "<leader>uu", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.startinsert()
end, { desc = "Terminal: vertical split" })

-- Open a terminal in a horizontal split below, in insert mode.
vim.keymap.set("n", "<leader>uU", function()
  vim.cmd.split()
  vim.cmd.term()
  vim.cmd.startinsert()
end, { desc = "Terminal: horizontal split" })

vim.keymap.set("n", "<leader>uc", function()
  floating_terminal.toggle({
    cmd = "codex",
    key = "codex",
    title = "codex",
  })
end, { desc = "Terminal: codex float" })

-- Get back to normal mode from terminal mode.
-- (Shadows the shell's <C-u> line-kill while inside :terminal.)
vim.keymap.set("t", "<C-u>", "<C-\\><C-n>")
