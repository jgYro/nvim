------------------
--
--
-- focus_float: jump into a floating popup and dim the buffer behind it
--
--
------------------

-- Shared by the LSP hover (K / <leader>k) and the gitsigns blame popup
-- (<leader>hb). When a float opens, we grey out the code behind it so the
-- popup stands out, focus into the float (so it's scrollable and `q` closes
-- it), and restore the colors when the float closes. Keeping this in one place
-- means hover and blame can't drift apart.

local M = {}

-- A single buffer-wide extmark in a high priority (above treesitter) recolours
-- every token to a muted grey. Refreshed on :colorscheme.
local dim_ns = vim.api.nvim_create_namespace("focus_float_dim")
local dimmed_buf = nil

local function set_dim_hl()
  vim.api.nvim_set_hl(0, "FocusFloatDim", { fg = "#3b3e48" })
end
set_dim_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("focus_float_dim_hl", { clear = true }),
  callback = set_dim_hl,
})

local function undim()
  if dimmed_buf and vim.api.nvim_buf_is_valid(dimmed_buf) then
    vim.api.nvim_buf_clear_namespace(dimmed_buf, dim_ns, 0, -1)
  end
  dimmed_buf = nil
end
M.undim = undim

local function dim(buf)
  undim()
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local last_line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""
  vim.api.nvim_buf_set_extmark(buf, dim_ns, 0, 0, {
    end_row = last,
    end_col = #last_line,
    hl_group = "FocusFloatDim",
    hl_eol = true,
    priority = 10000,
  })
  dimmed_buf = buf
end

-- Enter the float, allow leaving it (winfixbuf is cleared so <C-o> works), and
-- map buffer-local `q` to close it (so it never affects other floats).
local function focus_popup(win)
  if not (win and win > 0 and vim.api.nvim_win_is_valid(win)) then
    return false
  end
  vim.api.nvim_set_current_win(win)
  vim.wo[win].winfixbuf = false
  -- q and <C-o> both close the popup cleanly (which returns you to the window
  -- and cursor you came from). Mapping <C-o> here means it never runs the float's
  -- own jumplist -- which would otherwise load a buffer into the float and orphan
  -- it -- so <C-o> always just takes you back out.
  local pbuf = vim.api.nvim_win_get_buf(win)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = pbuf, nowait = true, desc = "Close popup" })
  vim.keymap.set("n", "<C-o>", "<cmd>close<cr>", { buffer = pbuf, nowait = true, desc = "Close popup (back)" })
  return true
end
M.focus_popup = focus_popup

-- Floats often open asynchronously (the LSP server / git has to answer first),
-- so instead of a fixed delay we poll find_win() briefly and act the instant
-- the float exists. find_win() returns the popup's window id, or nil/0 if it
-- isn't up yet. src_buf is the buffer to dim while the popup is open.
function M.focus_when_ready(src_buf, find_win, tries)
  local win = find_win()
  if win and win > 0 and vim.api.nvim_win_is_valid(win) then
    dim(src_buf)
    focus_popup(win)

    -- Tear down (undim + close the popup) whenever we leave it, by ANY means.
    -- WinClosed alone isn't enough: <C-o> inside a focused popup runs jumplist
    -- navigation, which loads the previous buffer INTO the float window without
    -- closing it -- leaving the popup orphaned and the dim stuck on. Hooking
    -- WinLeave/BufLeave on the popup buffer catches that (and plain window
    -- switches); WinClosed still covers `q`.
    local pbuf = vim.api.nvim_win_get_buf(win)
    local function teardown()
      undim()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end)
    end
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = undim,
    })
    vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
      buffer = pbuf,
      once = true,
      callback = teardown,
    })
  elseif tries > 0 then
    vim.defer_fn(function()
      M.focus_when_ready(src_buf, find_win, tries - 1)
    end, 16)
  end
end

return M
