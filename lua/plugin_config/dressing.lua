------------------
--
--
-- dressing (stevearc/dressing.nvim)
--
--
------------------

-- Replaces the default command-line vim.ui.input / vim.ui.select with floating
-- windows. This is what makes the llm_yank "LLM prompt" appear as a popup, and
-- also prettifies LSP code-action / rename pickers.
require("dressing").setup({
  input = {
    -- Float centered on the editor (relative="editor" -> dressing centers it
    -- both horizontally and vertically).
    border = "rounded",
    relative = "editor",
    prefer_width = 50,
    max_width = { 140, 0.9 },
    min_width = { 20, 0.2 },
  },
  select = {
    backend = { "builtin" }, -- floating list (no telescope dependency required)
    builtin = { border = "rounded" },
  },
})
