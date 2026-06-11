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
  default_command = "make -k ",
  -- baleia colorizes ANSI escapes in the *compilation* buffer (cargo, npm,
  -- pytest, etc. emit color). Requires the baleia.nvim dependency.
  baleia_setup = true,
  -- Follow output as it streams in, like Emacs' compilation buffer.
  auto_scroll = true,
  -- error_regexp_table is left at its defaults, which already recognize the
  -- common gcc/clang/rust/eslint/grep "file:line:col: message" formats. Pass
  -- a table here to extend (not replace) those defaults.
}

local compile_mode = require("compile-mode")

-- After every compilation, push the parsed errors into the quickfix list, and
-- open the quickfix window only when there's something to look at. This is the
-- "send to quickfix" bridge: from here, Lq/Hq step through compile errors.
vim.api.nvim_create_autocmd("User", {
  pattern = "CompilationFinished",
  desc = "Send compile-mode errors to the quickfix list",
  callback = function()
    compile_mode.send_to_qflist()
    if not vim.tbl_isempty(vim.fn.getqflist()) then
      vim.cmd("copen")
    end
  end,
})

-- Keybinds under the <leader>c ("compile") prefix.
--   <leader>cc  prompt for a command and run it (:Compile)
--   <leader>cr  rerun the last command (:Recompile)
--   <leader>ck  stop a running compilation (:CompileInterrupt)
--   <leader>cq  re-send current errors to the quickfix list (:QuickfixErrors)
vim.keymap.set("n", "<leader>cc", "<cmd>Compile<cr>", { desc = "Compile (prompt)" })
vim.keymap.set("n", "<leader>cr", "<cmd>Recompile<cr>", { desc = "Recompile (last command)" })
vim.keymap.set("n", "<leader>ck", "<cmd>CompileInterrupt<cr>", { desc = "Interrupt compilation" })
vim.keymap.set("n", "<leader>cq", "<cmd>QuickfixErrors<cr>", { desc = "Send errors to quickfix" })

-- Group label for the <leader>c prefix in the which-key popup.
local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({ { "<leader>c", group = "compile" } })
end
