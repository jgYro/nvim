------------------
--
--
-- watcher (jgYro/watcher.nvim)
--
--
------------------

-- Review external file changes before reloading: a floating, scrollable,
-- syntax-highlighted diff of buffer vs disk with accept / reject / cancel.
-- (Extracted from this config into its own plugin.)
require("watcher").setup({
  -- Also watch the whole project: prompt (open / diff / dismiss) for external
  -- changes and new files that aren't open in a buffer. Respects .gitignore.
  watch_cwd = {
    enabled = true,
    respect_gitignore = true,
    ignore = { "node_modules", ".DS_Store", "*.log" },
  },
})

-- Reopen the watcher review picker (e.g. to go back to it after opening a file).
vim.keymap.set("n", "<leader>w", require("watcher").open, { desc = "Watcher: review changes" })
