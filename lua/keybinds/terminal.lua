------------------
--
--
-- Terminal Keybinds
--
--
------------------

-- NOTE: terminal lives on <Space>u (not <Space>t) so it doesn't collide
-- with markdown-plus's table prefix (<Space>t...) in markdown buffers.

local codex_sessions = require("util.codex_sessions")

-- Open a terminal in a vertical split on the right, sized to 20% of the
-- screen width, in insert mode.
vim.keymap.set("n", "<leader>uu", function()
  vim.cmd.vnew()
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.2))
  vim.cmd.term()
  vim.cmd.startinsert()
end, { desc = "Terminal: vertical split" })

-- Open a terminal in a horizontal split below, sized to 20% of the screen
-- height, in insert mode.
vim.keymap.set("n", "<leader>uU", function()
  vim.cmd.split()
  vim.cmd("resize " .. math.floor(vim.o.lines * 0.2))
  vim.cmd.term()
  vim.cmd.startinsert()
end, { desc = "Terminal: horizontal split" })

vim.keymap.set("n", "<leader>uc", function()
  codex_sessions.toggle_current()
end, { desc = "Codex: toggle current session" })

vim.keymap.set("n", "<leader>uC", function()
  codex_sessions.new()
end, { desc = "Codex: new session" })

vim.keymap.set("n", "<leader>uk", function()
  codex_sessions.overview()
end, { desc = "Codex: workspace overview" })

vim.keymap.set("n", "<leader>uj", function()
  codex_sessions.changes()
end, { desc = "Codex: changed files" })

vim.keymap.set("n", "<leader>uA", function()
  codex_sessions.toggle_watcher_auto_accept()
end, { desc = "Codex: toggle watcher auto-accept" })

-- Get back to normal mode from terminal mode.
-- (Shadows the shell's <C-u> line-kill while inside :terminal.)
vim.keymap.set("t", "<C-u>", "<C-\\><C-n>")
