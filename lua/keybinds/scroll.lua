------------------
--
--
-- Scroll / Recenter Keybinds
--
--
------------------

-- zt/zb/zz keep their Vim defaults (top/bottom/center). With scrolloff=0 they
-- already land flush to the window edge, so no wrappers are needed.

-- <C-l> cycles center -> top -> bottom on repeated presses, like Emacs C-l.
-- This overrides Vim's default redraw-screen mapping.
local recenter_state = 0
vim.keymap.set("n", "<C-l>", function()
  local cmds = { "zz", "zt", "zb" }
  recenter_state = recenter_state % 3 + 1
  vim.cmd("normal! " .. cmds[recenter_state])
end, { desc = "Cycle recenter (center/top/bottom)" })
