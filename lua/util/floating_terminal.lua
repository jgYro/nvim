local M = {}

local terminals = {}

local function command_label(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end

  return cmd
end

local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function centered_float_config(opts)
  local columns = vim.o.columns
  local lines = math.max(1, vim.o.lines - vim.o.cmdheight - 1)
  local max_width = math.max(1, columns - 4)
  local max_height = math.max(1, lines - 2)
  local width = math.min(max_width, opts.width or math.floor(columns * 0.9))
  local height = math.min(max_height, opts.height or math.floor(lines * 0.85))

  return {
    relative = "editor",
    width = math.max(1, width),
    height = math.max(1, height),
    col = math.floor((columns - width) / 2),
    row = math.floor((lines - height) / 2),
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = "center",
  }
end

local function hide_current_float()
  local win = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_get_config(win).relative ~= "" then
    vim.api.nvim_win_close(win, true)
  end
end

local function configure_buffer(buf)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false

  vim.keymap.set("n", "q", hide_current_float, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Hide floating terminal",
  })
  vim.keymap.set("n", "<C-o>", hide_current_float, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Hide floating terminal (back)",
  })
end

local function configure_window(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

function M.toggle(opts)
  opts = opts or {}

  local cmd = opts.cmd or vim.o.shell
  local key = opts.key or command_label(cmd)
  local term = terminals[key]

  if term and valid_win(term.win) then
    vim.api.nvim_win_close(term.win, true)
    term.win = nil
    return
  end

  if not term then
    term = {}
    terminals[key] = term
  end

  if term.exited or not valid_buf(term.buf) then
    term.buf = vim.api.nvim_create_buf(false, true)
    term.exited = false
    term.started = false
    configure_buffer(term.buf)
  end

  term.win = vim.api.nvim_open_win(term.buf, true, centered_float_config(opts))
  configure_window(term.win)

  if not term.started then
    term.started = true
    local ok, job_id = pcall(vim.fn.jobstart, cmd, {
      term = true,
      cwd = opts.cwd or vim.fn.getcwd(),
      on_exit = function(_, code)
        term.exited = true
        term.job_id = nil

        if type(opts.on_exit) == "function" then
          opts.on_exit(code)
        end
      end,
    })

    if not ok or job_id <= 0 then
      term.started = false
      term.exited = true
      vim.notify("Failed to start floating terminal command: " .. command_label(cmd), vim.log.levels.ERROR)
      pcall(vim.api.nvim_win_close, term.win, true)
      term.win = nil
      return
    end

    term.job_id = job_id
  end

  vim.cmd.startinsert()
end

return M
