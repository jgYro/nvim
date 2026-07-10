------------------
--
--
-- foldfloat (jgYro/foldfloat.nvim)
--
--
------------------

local foldfloat = require("foldfloat")

local function jump_open(dir)
  local buf = vim.api.nvim_get_current_buf()
  local state = foldfloat._state[buf]
  local pattern = (state and state.section_pattern) or foldfloat.config.section_pattern
  local total = vim.api.nvim_buf_line_count(buf)
  local line = vim.api.nvim_win_get_cursor(0)[1] + dir

  while line >= 1 and line <= total do
    local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
    if text:match(pattern) then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      pcall(vim.cmd, "normal! zo")
      return
    end
    line = line + dir
  end
end

foldfloat.setup({
  keymaps = {
    extra = {
      { "n", function() jump_open(1) end, "foldfloat: next entry and open" },
      { "p", function() jump_open(-1) end, "foldfloat: previous entry and open" },
    },
  },
})
