------------------
--
--
-- Telescope (nvim-telescope/telescope.nvim)
--
--
------------------

-- Fuzzy finder. live_grep/grep_string use ripgrep and find_files uses fd
-- when available (both are installed via Homebrew). plenary.nvim must be on
-- the runtimepath first; it is listed before telescope in plugins/init.lua.

require("telescope").setup({
  defaults = {
    -- <C-/> in insert (and "?" in normal) shows this picker's keymaps.
    mappings = {
      i = { ["<C-h>"] = "which_key" },
    },
  },
})

-- Builtin pickers, all under the <Space>f ("find") prefix. The desc fields
-- are what which-key shows in its popup.
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep (ripgrep)" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume last picker" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>gl", builtin.git_bcommits, { desc = "Git buffer commits" })
vim.keymap.set("n", "<leader>gL", builtin.git_bcommits_range, { desc = "Git buffer commits (range)" })
vim.keymap.set("n", "<leader>km", builtin.keymaps, { desc = "Keymaps" })

-- Group label for the <Space>f prefix in the which-key popup. pcall keeps
-- this file independent of whether which-key is installed.
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({ { "<leader>f", group = "find (telescope)" } })
end
