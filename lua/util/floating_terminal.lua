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

function M.hide(key)
  local term = terminals[key]
  if term and valid_win(term.win) then
    vim.api.nvim_win_close(term.win, true)
    term.win = nil
    return true
  end

  return false
end

function M.is_open(key)
  local term = terminals[key]
  return term and valid_win(term.win) or false
end

function M.get(key)
  return terminals[key]
end

function M.open(opts)
  opts = opts or {}

  local cmd = opts.cmd or vim.o.shell
  local key = opts.key or command_label(cmd)
  local term = terminals[key]

  if not term then
    term = { key = key }
    terminals[key] = term
  end

  term.cmd = cmd

  if not valid_buf(term.buf) or (term.exited and not opts.preserve_on_exit) then
    term.buf = vim.api.nvim_create_buf(false, true)
    term.exited = false
    term.started = false
    configure_buffer(term.buf)

    if type(opts.on_create) == "function" then
      opts.on_create(term.buf, term)
    end
  end

  if valid_win(term.win) then
    vim.api.nvim_set_current_win(term.win)
  else
    term.win = vim.api.nvim_open_win(term.buf, true, centered_float_config(opts))
  end

  configure_window(term.win)

  if type(opts.on_open) == "function" then
    opts.on_open(term.win, term.buf, term)
  end

  if not term.started and not term.exited then
    term.started = true
    local ok, job_id = pcall(vim.fn.jobstart, cmd, {
      term = true,
      cwd = opts.cwd or vim.fn.getcwd(),
      on_exit = function(_, code)
        term.exited = true
        term.job_id = nil

        if type(opts.on_exit) == "function" then
          opts.on_exit(code, term)
        end
      end,
    })

    if not ok or type(job_id) ~= "number" or job_id <= 0 then
      term.started = false
      term.exited = true
      vim.notify("Failed to start floating terminal command: " .. command_label(cmd), vim.log.levels.ERROR)
      pcall(vim.api.nvim_win_close, term.win, true)
      term.win = nil

      if type(opts.on_fail) == "function" then
        opts.on_fail(term)
      end

      return
    end

    term.job_id = job_id

    if type(opts.on_start) == "function" then
      opts.on_start(job_id, term)
    end
  end

  if opts.startinsert ~= false and not term.exited then
    vim.cmd.startinsert()
  end

  return term
end

function M.toggle(opts)
  opts = opts or {}

  local cmd = opts.cmd or vim.o.shell
  local key = opts.key or command_label(cmd)

  if M.hide(key) then
    return
  end

  return M.open(opts)
end

return M
