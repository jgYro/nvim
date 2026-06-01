------------------
--
--
-- Clipboard Keybinds
--
--
------------------

-- Copy to the system clipboard (the "+" register). On macOS "+" and "*"
-- are the same pasteboard. Works in normal and visual mode.
vim.keymap.set("n", "<leader>y", '"+y', { noremap = true, silent = true })
vim.keymap.set("v", "<leader>y", '"+y', { noremap = true, silent = true })

-- Paste from the system clipboard.
vim.keymap.set("n", "<leader>p", '"+p', { noremap = true, silent = true })
vim.keymap.set("v", "<leader>p", '"+p', { noremap = true, silent = true })
