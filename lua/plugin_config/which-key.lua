------------------
--
--
-- which-key (folke/which-key.nvim)
--
--
------------------

-- which-key shows a popup of possible keybindings after you start a prefix
-- (e.g. <Space>). It auto-discovers any mapping that has a `desc`, so
-- markdown-plus keymaps already appear on their own. The value we add here
-- is *group labels* for the prefixes, so the popup reads "markdown",
-- "tables", "headings" instead of a flat list of cryptic keys.

local wk = require("which-key")

wk.setup({
  preset = "classic",
  delay = 200,
})

-- Group labels for the markdown-plus keymaps. Registered buffer-locally on
-- markdown filetypes only, since that is the only place these prefixes are
-- mapped. <localleader> resolves to <Space> (see config/options.lua).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = vim.api.nvim_create_augroup("which_key_markdown", { clear = true }),
  callback = function(ev)
    wk.add({
      buffer = ev.buf,
      { "<localleader>m", group = "markdown" },
      { "<localleader>mf", group = "footnotes" },
      { "<localleader>mQ", group = "callouts / quotes" },
      { "<localleader>h", group = "headings / TOC" },
      { "<localleader>t", group = "tables" },
      { "<localleader>ti", group = "table: insert" },
      { "<localleader>td", group = "table: delete" },
      { "<localleader>ty", group = "table: yank" },
      { "<localleader>ts", group = "table: sort" },
    })
  end,
})
