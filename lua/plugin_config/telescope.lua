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

local actions = require("telescope.actions")

-- Shared picker mappings, matching the nvim-tree preview:
--   C-d/C-u  scroll preview down/up
--   C-l/C-h  scroll preview right/left
--   C--      open selection in a horizontal split (- looks horizontal)
--   C-|      open selection in a vertical split   (| looks vertical)
-- Applied in both insert and normal mode.
local picker_maps = {
  ["<C-d>"] = actions.preview_scrolling_down,
  ["<C-u>"] = actions.preview_scrolling_up,
  ["<C-l>"] = actions.preview_scrolling_right,
  ["<C-h>"] = actions.preview_scrolling_left,
  ["<C-->"] = actions.select_horizontal,
  -- Vertical split, bound to every way Ctrl+| can arrive: <C-bar> (kitty
  -- protocol), <C-S-Bslash> (tmux csi-u: base key \ + shift), and <C-Bslash>
  -- (iTerm2 legacy, where Ctrl+| collapses to Ctrl+\ = ^\).
  ["<C-bar>"] = actions.select_vertical,
  ["<C-S-Bslash>"] = actions.select_vertical,
  ["<C-Bslash>"] = actions.select_vertical,
}

require("telescope").setup({
  defaults = {
    -- which_key (this picker's keymap cheatsheet) stays on its defaults: <C-/>
    -- in insert and "?" in normal. We free up <C-h> for scroll-left.
    mappings = {
      i = picker_maps,
      n = picker_maps,
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
vim.keymap.set("n", "<leader>fq", builtin.quickfix, { desc = "Find in quickfix list" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>gl", builtin.git_bcommits, { desc = "Git buffer commits" })
vim.keymap.set("n", "<leader>gL", builtin.git_bcommits_range, { desc = "Git buffer commits (range)" })
vim.keymap.set("n", "<leader>km", builtin.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>lr", builtin.lsp_references, { desc = "LSP references" })
vim.keymap.set("n", "<leader>sp", builtin.spell_suggest, { desc = "Spelling suggestions" })

-- Group label for the <Space>f prefix in the which-key popup. pcall keeps
-- this file independent of whether which-key is installed.
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({ { "<leader>f", group = "find (telescope)" } })
end
