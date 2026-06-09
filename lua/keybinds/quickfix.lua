------------------
--
--
-- Quickfix Keybinds
--
--
------------------

-- Step through the quickfix list: Lq -> next entry, Hq -> previous entry.
-- These wrap around: :cnext past the last entry jumps to the first (:cfirst),
-- and :cprevious before the first jumps to the last (:clast). pcall swallows
-- the E553 "no more items" error that signals we hit the end.
local function try(cmd)
  return pcall(function() vim.cmd(cmd) end)
end
vim.keymap.set("n", "Lq", function()
  if not try("cnext") then
    try("cfirst")
  end
end, { desc = "Next quickfix entry (wraps)" })
vim.keymap.set("n", "Hq", function()
  if not try("cprevious") then
    try("clast")
  end
end, { desc = "Previous quickfix entry (wraps)" })

-- <leader>q toggles the quickfix window: open it if closed, close it if open.
-- We detect an open quickfix window by scanning the current tab's windows for
-- one whose buffer has quickfix=1.
vim.keymap.set("n", "<leader>q", function()
  local is_open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      is_open = true
      break
    end
  end
  if is_open then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix window" })

