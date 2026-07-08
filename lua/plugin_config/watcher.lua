------------------
--
--
-- watcher (jgYro/watcher.nvim)
--
--
------------------

-- Review external file changes before reloading. watcher.nvim still detects
-- changes, but automatic review dispatch is routed into the shared Codex
-- dashboard instead of opening its own picker/float over Codex terminals.
local watcher = require("watcher")
local codex_sessions = require("util.codex_sessions")

codex_sessions.setup({
  watcher = {
    -- When true, watcher changes are accepted as soon as watcher detects them.
    -- Leave this off by default because accepting a changed open buffer runs
    -- watcher.nvim's normal accept action (`:edit!`).
    auto_accept = false,
    -- Keep detection, but route automatic review dispatch into the Codex
    -- dashboard instead of opening a picker/float over the Codex terminal.
    intercept_review = true,
  },
})

watcher.setup({
  -- Also watch the whole project: prompt (open / diff / dismiss) for external
  -- changes and new files that aren't open in a buffer. Respects .gitignore.
  watch_cwd = {
    enabled = true,
    respect_gitignore = true,
    ignore = { "node_modules", ".DS_Store", "*.log" },
  },
})
codex_sessions.attach_watcher(watcher)

-- Review watcher changes in the shared Codex dashboard instead of opening a
-- separate watcher picker/float over an active Codex terminal.
vim.keymap.set("n", "<leader>w", codex_sessions.changes, { desc = "Watcher: review changes" })
