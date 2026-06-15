------------------
--
--
-- Scroll / Recenter Keybinds
--
--
------------------

-- zt/zb/zz keep their Vim defaults (top/bottom/center). With scrolloff=0 they
-- already land flush to the window edge, so no wrappers are needed.

-- zl moves the CURSOR (not the page) to the middle -> top -> bottom of the
-- currently visible lines, cycling on repeated presses. The viewport stays put
-- -- if line 116 is centered, it stays centered while the cursor hops to the
-- top (~line 86) or bottom (~line 146) of the screen. This is just Vim's
-- H/M/L combined into one cycling key. (zl's default is horizontal
-- scroll-right, unused here since lines wrap.)
local cursor_pos_state = 0
vim.keymap.set("n", "zl", function()
  local cmds = { "M", "H", "L" } -- middle, top (High), bottom (Low) of screen
  cursor_pos_state = cursor_pos_state % 3 + 1
  vim.cmd("normal! " .. cmds[cursor_pos_state])
end, { desc = "Cycle cursor in view (middle/top/bottom)" })
