------------------
--
--
-- cheat.sh
--
--
------------------

local cheat = require("cheat_sh")

cheat.setup()

vim.keymap.set("n", "<leader>ss", cheat.prompt, { desc = "cheat.sh query" })
vim.keymap.set("n", "<leader>sw", cheat.word, { desc = "cheat.sh word under cursor" })
vim.keymap.set("n", "<leader>sf", cheat.filetype, { desc = "cheat.sh filetype" })

local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({ { "<leader>s", group = "cheat.sh" } })
end
