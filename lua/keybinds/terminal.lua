------------------
--
--
-- Terminal Keybinds
--
--
------------------

-- NOTE: terminal lives on <Space>u (not <Space>t) so it doesn't collide
-- with markdown-plus's table prefix (<Space>t...) in markdown buffers.

-- Open a terminal in a vertical split on the right, in insert mode.
vim.keymap.set("n", "<space>u", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.startinsert()
end)

-- Open a terminal in a horizontal split below, in insert mode.
vim.keymap.set("n", "<space>U", function()
  vim.cmd.split()
  vim.cmd.term()
  vim.cmd.startinsert()
end)

-- Get back to normal mode from terminal mode.
-- (Shadows the shell's <C-u> line-kill while inside :terminal.)
vim.keymap.set('t', '<C-u>', "<C-\\><C-n>")

