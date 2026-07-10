------------------
--
--
-- compile-mode (ej-shafran/compile-mode.nvim)
--
--
------------------

-- Emacs-style compilation mode: run a build/test/grep command asynchronously
-- into a *compilation* buffer, parse the output for file:line:col errors, and
-- step through them. We bridge those errors into the quickfix list so the
-- existing quickfix workflow drives them (Lq/Hq to step, <leader>q to toggle).

-- Config is read from this global (see :help compile-mode-configuration). It
-- must be set before any compile-mode command runs.
vim.g.compile_mode = {
  -- -k keeps going after the first failed target, so we collect every error
  -- in one pass instead of stopping at the first.
  default_command = "",
  -- baleia colorizes ANSI escapes in the *compilation* buffer (cargo, npm,
  -- pytest, etc. emit color). Requires the baleia.nvim dependency.
  baleia_setup = true,
  -- Follow output as it streams in, like Emacs' compilation buffer.
  auto_scroll = true,
  -- Jump to the compilation buffer as soon as a compile starts.
  focus_compilation_buffer = true,
  -- error_regexp_table is left at its defaults, which already recognize the
  -- common gcc/clang/rust/eslint/grep "file:line:col: message" formats. Pass
  -- a table here to extend (not replace) those defaults.
}

local compile_mode = require("compile-mode")
local compile_utils = require("compile-mode.utils")
local compile_buffer_fraction = 0.25

local function compile_window_height()
  local editor_lines = math.max(1, vim.o.lines - vim.o.cmdheight - 1)
  return math.max(5, math.floor(editor_lines * compile_buffer_fraction))
end

local function resize_compilation_windows()
  local bufnr = vim.g.compilation_buffer
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local height = compile_window_height()
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      pcall(vim.api.nvim_win_set_height, win, height)
    end
  end
end

local function resize_compilation_soon()
  vim.schedule(resize_compilation_windows)
  vim.defer_fn(resize_compilation_windows, 50)
  vim.defer_fn(resize_compilation_windows, 200)
end

local function compile_params()
  return {
    count = compile_window_height(),
    smods = { split = "botright" },
  }
end

local function compile_prompt()
  local original_input = compile_utils.input

  compile_utils.input = function(opts)
    compile_utils.input = original_input
    opts = vim.tbl_extend("force", opts or {}, { default = "" })
    local command = original_input(opts)
    resize_compilation_soon()
    return command
  end

  compile_mode.compile(compile_params())
end

local function recompile()
  compile_mode.recompile(compile_params())
  resize_compilation_soon()
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "compilation",
  group = vim.api.nvim_create_augroup("compile_mode_window", { clear = true }),
  desc = "Keep the compilation buffer at 25% of the editor height",
  callback = resize_compilation_windows,
})

-- After every compilation, push the parsed errors into the quickfix list, and
-- open the quickfix window only when there's something to look at. This is the
-- "send to quickfix" bridge: from here, Lq/Hq step through compile errors.
vim.api.nvim_create_autocmd("User", {
  pattern = "CompilationFinished",
  desc = "Send compile-mode errors to the quickfix list",
  callback = function()
    compile_mode.send_to_qflist()
    if not vim.tbl_isempty(vim.fn.getqflist()) then
      local current_win = vim.api.nvim_get_current_win()
      vim.cmd("copen")
      if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
      end
      resize_compilation_windows()
    end
  end,
})

-- Keybinds under the <leader>c ("compile") prefix.
--   <leader>cc  prompt for a command and run it (:Compile)
--   <leader>cr  rerun the last command (:Recompile)
--   <leader>ck  stop a running compilation (:CompileInterrupt)
--   <leader>cq  re-send current errors to the quickfix list (:QuickfixErrors)
vim.keymap.set("n", "<leader>cc", compile_prompt, { desc = "Compile (prompt)" })
vim.keymap.set("n", "<leader>cr", recompile, { desc = "Recompile (last command)" })
vim.keymap.set("n", "<leader>ck", "<cmd>CompileInterrupt<cr>", { desc = "Interrupt compilation" })
vim.keymap.set("n", "<leader>cq", "<cmd>QuickfixErrors<cr>", { desc = "Send errors to quickfix" })

-- Group label for the <leader>c prefix in the which-key popup.
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({ { "<leader>c", group = "compile" } })
end
