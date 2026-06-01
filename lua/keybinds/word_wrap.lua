------------------
--
--
-- Word Wrap Keybinds
--
--
------------------

-- Toggle word wrap for the current window, echoing the new state.
vim.keymap.set('n', '<space><space>w', function()
  if vim.wo.wrap then
    vim.wo.wrap = false
    vim.cmd('echo "Word wrapping OFF"')
  else
    vim.wo.wrap = true
    vim.cmd('echo "Word wrapping ON"')
  end
end)

