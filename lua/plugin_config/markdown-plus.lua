------------------
--
--
-- markdown-plus (YousefHadder/markdown-plus.nvim)
--
--
------------------

-- Markdown editing enhancements: heading toggles, thematic breaks, code
-- blocks, inline formatting, tables. Keymaps use <localleader> and only
-- attach to markdown buffers.
require("markdown-plus").setup({
  keymaps = { enabled = true },
  table = { keymaps = { enabled = true } },
})
