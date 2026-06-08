------------------
--
--
-- yank2think (jgYro/yank2think.nvim)
--
--
------------------

-- Collect code selections into an LLM-ready markdown buffer:
--   <leader>Y (visual)      -> append the selection as an entry
--   <C-y>     (normal/visual)-> open the foldable/editable think buffer; press
--                               `y` there to copy everything (with metadata) to
--                               the system clipboard.
-- Sibling of the plain <leader>y (raw copy) in keybinds/clipboard.lua.
-- (Extracted from this config into its own plugin.)
--
-- The `format` function below controls exactly how each appended entry looks --
-- edit it here to change the markdown. It gets one `entry` and returns lines:
--   entry = { path, l1, l2, range = "L12-30", lang, lines = {..}, prompt }
-- If you change the header (the first line), keep `section_pattern` matching it
-- so the foldable view and entry count keep working.
require("yank2think").setup({
  add_keymap = "<leader>Y",
  open_keymap = "<C-y>",
  register = "+",
  prompt = true,
  section_pattern = "^## ",
  format = function(entry)
    local out = { ("## %s (%s)"):format(entry.path, entry.range) }
    if entry.prompt and entry.prompt ~= "" then
      table.insert(out, "> " .. entry.prompt)
    end
    table.insert(out, "")
    table.insert(out, "```" .. (entry.lang or ""))
    vim.list_extend(out, entry.lines)
    table.insert(out, "```")
    return out
  end,
})
