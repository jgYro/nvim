------------------
--
--
-- Harpoon (theprimeagen/harpoon, v1)
--
--
------------------

-- Quick file marks + jump list. This is the v1 API (harpoon.mark /
-- harpoon.ui); harpoon2 uses a different module layout. Depends on
-- plenary.nvim, listed before this in plugins/init.lua.

require("harpoon").setup({})

local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

-- Compat shim for newer Neovim. harpoon v1's toggle_quick_menu() runs
--   autocmd BufModifiedSet <buffer> set nomodified
-- but this Neovim build doesn't define the BufModifiedSet event, so the
-- command throws E216 and aborts the rest of toggle_quick_menu() (including
-- its auto-close-on-leave autocmd). We wrap toggle_quick_menu and, only for
-- the duration of that call, swap in a vim.cmd that silently drops that one
-- autocmd. The menu buffer is `acwrite`, so skipping it is harmless. Doing
-- it here keeps the plugin's own files untouched (they'd be overwritten on
-- update).
if vim.fn.exists("##BufModifiedSet") == 0 then
  local real_toggle = ui.toggle_quick_menu
  ui.toggle_quick_menu = function(...)
    local real_cmd = vim.cmd
    vim.cmd = setmetatable({}, {
      __index = real_cmd, -- delegate vim.cmd.<method> forms to the original
      __call = function(_, c)
        if type(c) == "string" and c:find("autocmd BufModifiedSet", 1, true) then
          return
        end
        return real_cmd(c)
      end,
    })
    local ok, err = pcall(real_toggle, ...)
    vim.cmd = real_cmd
    if not ok then
      error(err)
    end
  end
end

-- Add the current file to the harpoon list, and toggle the picker menu.
vim.keymap.set("n", "<leader>a", mark.add_file, { desc = "Harpoon add file" })
vim.keymap.set("n", "<leader>e", ui.toggle_quick_menu, { desc = "Harpoon menu" })

-- Jump straight to harpoon slots 1-4.
-- NOTE: <C-;> usually only works in GUI clients (Neovide); most terminals
-- can't send Ctrl-; as a distinct key. Swap it if slot 4 doesn't fire.
vim.keymap.set("n", "<C-j>", function() ui.nav_file(1) end, { desc = "Harpoon file 1" })
vim.keymap.set("n", "<C-k>", function() ui.nav_file(2) end, { desc = "Harpoon file 2" })
vim.keymap.set("n", "<C-l>", function() ui.nav_file(3) end, { desc = "Harpoon file 3" })
vim.keymap.set("n", "<C-;>", function() ui.nav_file(4) end, { desc = "Harpoon file 4" })
