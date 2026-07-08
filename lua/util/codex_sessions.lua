local floating_terminal = require("util.floating_terminal")

local M = {}

local IDLE_MS = 3000
local VIEW_ORDER = { "overview", "sessions", "changes" }
local DASHBOARD_TITLE = "codex workspace  |  <C-j>/<C-k> tabs  |  q close"

M.config = {
  watcher = {
    auto_accept = false,
    intercept_review = true,
    notify_pending = true,
  },
}

local sessions = {}
local current_index = nil
local next_id = 1
local dashboard_view = "overview"
local dashboard_buf = nil
local dashboard_win = nil
local watcher_state = {
  module = nil,
  original_review = nil,
  last_notice_key = nil,
}

local uv = vim.uv or vim.loop

local function now()
  return uv.now()
end

local function session_title(session)
  return ("codex #%d"):format(session.id)
end

local function session_key(id)
  return ("codex:%d"):format(id)
end

local function find_index_by_buf(buf)
  for i, session in ipairs(sessions) do
    if session.buf == buf then
      return i
    end
  end
end

local function find_index_by_id(id)
  for i, session in ipairs(sessions) do
    if session.id == id then
      return i
    end
  end
end

local function active_index()
  return find_index_by_buf(vim.api.nvim_get_current_buf()) or current_index or 1
end

local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_dashboard_buf(buf)
  return valid_buf(buf) and vim.b[buf].codex_dashboard == true
end

local function current_dashboard()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  if is_dashboard_buf(current_buf) then
    return current_win, current_buf
  end

  if valid_win(dashboard_win) and is_dashboard_buf(dashboard_buf) then
    return dashboard_win, dashboard_buf
  end
end

local function relpath(path)
  return vim.fn.fnamemodify(path, ":.")
end

local function watcher()
  if watcher_state.module then
    return watcher_state.module
  end

  local ok, mod = pcall(require, "watcher")
  if ok then
    watcher_state.module = mod
    return mod
  end
end

local function pending_changes()
  local mod = watcher()
  if not mod or type(mod.get_pending) ~= "function" then
    return {}
  end

  local ok, entries = pcall(mod.get_pending)
  if not ok or type(entries) ~= "table" then
    return {}
  end

  return entries
end

local function pending_signature(entries)
  local parts = {}
  for _, entry in ipairs(entries) do
    parts[#parts + 1] = table.concat({ entry.path or "", entry.kind or "", entry.reason or "" }, "\t")
  end
  return table.concat(parts, "\n")
end

local function status_for(session)
  local term = floating_terminal.get(session.key)
  if term and term.exited then
    return "exited"
  end

  return session.state or "completed"
end

local function overview_counts()
  local counts = { busy = 0, completed = 0, exited = 0 }
  for _, session in ipairs(sessions) do
    local status = status_for(session)
    counts[status] = (counts[status] or 0) + 1
  end
  return counts
end

local function elapsed(ms)
  if not ms then
    return "never"
  end

  local seconds = math.max(0, math.floor((now() - ms) / 1000))
  if seconds < 60 then
    return ("%ds ago"):format(seconds)
  end

  local minutes = math.floor(seconds / 60)
  if minutes < 60 then
    return ("%dm ago"):format(minutes)
  end

  return ("%dh ago"):format(math.floor(minutes / 60))
end

local function mark_completed_after_idle(session, seq)
  vim.defer_fn(function()
    if session.activity_seq == seq and session.state == "busy" then
      session.state = "completed"
    end
  end, IDLE_MS)
end

local function mark_busy(session)
  if session.state == "exited" then
    return
  end

  session.state = "busy"
  session.last_activity = now()
  session.activity_seq = session.activity_seq + 1
  mark_completed_after_idle(session, session.activity_seq)
end

local function mark_exited(session, code)
  session.state = "exited"
  session.exit_code = code
  session.job_id = nil
  session.last_activity = now()
  session.activity_seq = session.activity_seq + 1
end

local function make_session()
  local id = next_id
  next_id = next_id + 1

  local session = {
    id = id,
    key = session_key(id),
    cwd = vim.fn.getcwd(),
    state = "busy",
    created_at = now(),
    last_activity = nil,
    activity_seq = 0,
    buf = nil,
    job_id = nil,
    exit_code = nil,
  }

  table.insert(sessions, session)
  return session, #sessions
end

local function switch_dashboard(dir)
  local current = 1
  for i, view in ipairs(VIEW_ORDER) do
    if view == dashboard_view then
      current = i
      break
    end
  end

  local next_view = VIEW_ORDER[((current - 1 + dir) % #VIEW_ORDER) + 1]
  M.dashboard(next_view)
end

local function map_session_keys(buf)
  vim.keymap.set("n", "<C-l>", M.next, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: next session",
  })
  vim.keymap.set("t", "<C-l>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').next()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: next session",
  })
  vim.keymap.set("n", "<C-h>", M.prev, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: previous session",
  })
  vim.keymap.set("t", "<C-h>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').prev()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: previous session",
  })
  vim.keymap.set("n", "<C-k>", function()
    M.dashboard("overview")
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: dashboard",
  })
  vim.keymap.set("t", "<C-k>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').dashboard('overview')<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: dashboard",
  })
  vim.keymap.set("n", "<C-j>", function()
    M.dashboard("changes")
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: changed files",
  })
  vim.keymap.set("t", "<C-j>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').dashboard('changes')<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: changed files",
  })
end

local function attach_activity(session, buf)
  pcall(vim.api.nvim_buf_attach, buf, false, {
    on_lines = function(_, changed_buf)
      if changed_buf == session.buf then
        mark_busy(session)
      end
    end,
    on_detach = function(_, detached_buf)
      if detached_buf == session.buf then
        session.buf = nil
      end
    end,
  })
end

local function on_create(session)
  return function(buf)
    session.buf = buf
    map_session_keys(buf)
    attach_activity(session, buf)
  end
end

local function on_start(session)
  return function(job_id)
    session.job_id = job_id
    mark_busy(session)
  end
end

local function on_exit(session)
  return function(code)
    mark_exited(session, code)
  end
end

local function on_fail(session)
  return function()
    mark_exited(session, -1)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open(index)
  if #sessions == 0 then
    local _, created_index = make_session()
    index = created_index
  end

  index = index or active_index()
  local session = sessions[index]
  if not session then
    vim.notify("No Codex session " .. tostring(index), vim.log.levels.WARN)
    return
  end

  local previous = current_index and sessions[current_index]
  if previous and previous.key ~= session.key then
    floating_terminal.hide(previous.key)
  end

  current_index = index

  local term = floating_terminal.open({
    cmd = "codex",
    key = session.key,
    title = session_title(session),
    cwd = session.cwd,
    preserve_on_exit = true,
    on_create = on_create(session),
    on_start = on_start(session),
    on_exit = on_exit(session),
    on_fail = on_fail(session),
  })

  if term then
    session.buf = term.buf
    session.job_id = term.job_id
  end

  return term
end

function M.toggle_current()
  if #sessions == 0 then
    return M.new()
  end

  local index = active_index()
  local session = sessions[index]
  if session and floating_terminal.is_open(session.key) then
    floating_terminal.hide(session.key)
    return
  end

  return M.open(index)
end

function M.new()
  local _, index = make_session()
  return M.open(index)
end

function M.next()
  if #sessions == 0 then
    return M.new()
  end

  local index = active_index()
  return M.open((index % #sessions) + 1)
end

function M.prev()
  if #sessions == 0 then
    return M.new()
  end

  local index = active_index()
  return M.open(((index - 2) % #sessions) + 1)
end

local function tabs_line(active)
  local changes = #pending_changes()
  local parts = {}
  for _, view in ipairs(VIEW_ORDER) do
    local label = view
    if view == "sessions" then
      label = ("sessions (%d)"):format(#sessions)
    elseif view == "changes" then
      label = ("changes (%d)"):format(changes)
    end

    if view == active then
      parts[#parts + 1] = "[" .. label .. "]"
    else
      parts[#parts + 1] = label
    end
  end

  return table.concat(parts, " | ")
end

local function add_header(lines, active, hint)
  lines[#lines + 1] = "# Codex workspace"
  lines[#lines + 1] = ""
  lines[#lines + 1] = tabs_line(active)
  lines[#lines + 1] = ""
  lines[#lines + 1] = hint or "`<C-j>/<C-k>` tabs | `<Tab>` details | q close"
  lines[#lines + 1] = ""
end

local function overview_lines()
  local counts = overview_counts()
  local changes = #pending_changes()
  local lines = {}

  add_header(lines, "overview", "`<C-j>/<C-k>` tabs | `<CR>` open section | `T` auto-accept")
  lines[#lines + 1] = "## Sessions"
  lines[#lines + 1] = ""
  lines[#lines + 1] = ("- total: %d"):format(#sessions)
  lines[#lines + 1] = ("- busy: %d"):format(counts.busy or 0)
  lines[#lines + 1] = ("- completed: %d"):format(counts.completed or 0)
  lines[#lines + 1] = ("- exited: %d"):format(counts.exited or 0)
  if current_index and sessions[current_index] then
    lines[#lines + 1] = ("- current: codex #%d"):format(sessions[current_index].id)
  else
    lines[#lines + 1] = "- current: none"
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Changes"
  lines[#lines + 1] = ""
  lines[#lines + 1] = ("- pending files: %d"):format(changes)
  lines[#lines + 1] = ("- auto-accept: %s"):format(M.config.watcher.auto_accept and "on" or "off")
  lines[#lines + 1] = "- source: watcher.nvim pending registry"
  lines[#lines + 1] = ""

  return lines
end

local function sessions_lines()
  local counts = overview_counts()
  local lines = {}

  add_header(lines, "sessions", "`<CR>` open session | `<C-j>/<C-k>` tabs | `<Tab>` details")
  lines[#lines + 1] = ("%d total | %d busy | %d completed | %d exited"):format(
    #sessions,
    counts.busy or 0,
    counts.completed or 0,
    counts.exited or 0
  )
  lines[#lines + 1] = ""

  if #sessions == 0 then
    lines[#lines + 1] = "No Codex sessions yet."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Use `<leader>uc` to start one, or `<leader>uC` to create another instance."
    return lines
  end

  for i, session in ipairs(sessions) do
    local status = status_for(session)
    local flags = {}

    if i == current_index then
      flags[#flags + 1] = "current"
    end
    if floating_terminal.is_open(session.key) then
      flags[#flags + 1] = "visible"
    end

    local suffix = #flags > 0 and (" [" .. table.concat(flags, ", ") .. "]") or ""
    lines[#lines + 1] = ("## codex #%d [%s]%s"):format(session.id, status, suffix)
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("- cwd: `%s`"):format(session.cwd)
    lines[#lines + 1] = ("- buffer: `%s`"):format(session.buf or "none")
    lines[#lines + 1] = ("- job: `%s`"):format(session.job_id or "none")
    lines[#lines + 1] = ("- created: %s"):format(elapsed(session.created_at))
    lines[#lines + 1] = ("- last output: %s"):format(elapsed(session.last_activity))
    if status == "exited" then
      lines[#lines + 1] = ("- exit code: `%s`"):format(session.exit_code or "unknown")
    end
    lines[#lines + 1] = ""
  end

  return lines
end

local function diff_lines(entry)
  local mod = watcher()
  if not mod or type(mod.diff_lines) ~= "function" then
    return { "(watcher.nvim is not available)" }
  end

  local ok, lines = pcall(mod.diff_lines, entry)
  if ok and type(lines) == "table" then
    return lines
  end

  return { "(failed to build diff)" }
end

local function changes_lines()
  local entries = pending_changes()
  local lines = {}

  add_header(
    lines,
    "changes",
    "`<CR>/o` open | `a` accept | `r` reject | `x` dismiss | `A` accept all | `T` auto-accept"
  )
  lines[#lines + 1] = ("Auto-accept is %s. Pending files: %d."):format(
    M.config.watcher.auto_accept and "on" or "off",
    #entries
  )
  lines[#lines + 1] = ""

  if #entries == 0 then
    lines[#lines + 1] = "No pending watcher changes."
    lines[#lines + 1] = ""
    return lines
  end

  for i, entry in ipairs(entries) do
    lines[#lines + 1] = ("## [%d] %s %s: %s"):format(
      i,
      entry.reason or "changed",
      entry.kind or "file",
      relpath(entry.path)
    )
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("- path: `%s`"):format(entry.path)
    lines[#lines + 1] = ("- kind: `%s`"):format(entry.kind or "unknown")
    lines[#lines + 1] = ("- reason: `%s`"):format(entry.reason or "unknown")
    if entry.buf then
      lines[#lines + 1] = ("- buffer: `%s`"):format(entry.buf)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "```diff"
    vim.list_extend(lines, diff_lines(entry))
    lines[#lines + 1] = "```"
    lines[#lines + 1] = ""
  end

  return lines
end

local function selected_heading()
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  for lnum = line, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
    local heading = text:match("^##%s+(.+)$")
    if heading then
      return heading
    end
  end
end

local function selected_session_index()
  local heading = selected_heading() or ""
  local id = tonumber(heading:match("^codex #(%d+)"))
  return id and find_index_by_id(id) or nil
end

local function selected_change_entry()
  local heading = selected_heading() or ""
  local index = tonumber(heading:match("^%[(%d+)%]"))
  if not index then
    return nil
  end

  return pending_changes()[index]
end

local function focus_file_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= "terminal" then
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end

  return false
end

local function open_change_file(entry)
  pcall(vim.cmd, "close")
  vim.schedule(function()
    if not focus_file_window() then
      vim.cmd("tabnew")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
    entry.kind, entry.buf, entry.visited = "buffer", vim.api.nvim_get_current_buf(), true
  end)
end

local function redraw_dashboard(lines)
  local win, buf = current_dashboard()
  if not (valid_win(win) and is_dashboard_buf(buf)) then
    return false
  end

  dashboard_win = win
  dashboard_buf = buf
  vim.api.nvim_set_current_win(win)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_win_set_cursor, win, { 1, 0 })
  vim.wo[win].foldlevel = 0
  vim.wo[win].foldenable = true
  pcall(vim.api.nvim_win_call, win, function()
    vim.cmd("normal! zM")
  end)

  return true
end

local function refresh_dashboard(view)
  M.dashboard(view or dashboard_view)
end

local function open_selected_session()
  local index = selected_session_index()
  if not index then
    vim.notify("No Codex session under cursor", vim.log.levels.WARN)
    return
  end

  pcall(vim.cmd, "close")
  vim.schedule(function()
    M.open(index)
  end)
end

local function act_selected_change(action)
  local entry = selected_change_entry()
  if not entry then
    vim.notify("No watcher change under cursor", vim.log.levels.WARN)
    return
  end

  if action == "open" then
    open_change_file(entry)
    return
  end

  local mod = watcher()
  if not mod or type(mod.act) ~= "function" then
    vim.notify("watcher.nvim is not available", vim.log.levels.WARN)
    return
  end

  pcall(mod.act, entry, action)
  refresh_dashboard("changes")
end

local function open_selected_dashboard_item()
  if dashboard_view == "sessions" then
    open_selected_session()
    return
  end

  if dashboard_view == "changes" then
    act_selected_change("open")
    return
  end

  local heading = selected_heading() or ""
  if heading:match("^Sessions") then
    refresh_dashboard("sessions")
  elseif heading:match("^Changes") then
    refresh_dashboard("changes")
  end
end

function M.accept_all_watcher_changes(opts)
  opts = opts or {}

  local mod = watcher()
  if not mod or type(mod.act) ~= "function" then
    return
  end

  local entries = pending_changes()
  for _, entry in ipairs(entries) do
    pcall(mod.act, entry, "accept")
  end

  watcher_state.last_notice_key = nil

  if not opts.quiet then
    vim.notify(("watcher: accepted %d pending change(s)"):format(#entries), vim.log.levels.INFO)
  end
end

function M.handle_watcher_review()
  if not M.config.watcher.intercept_review and watcher_state.original_review then
    return watcher_state.original_review()
  end

  local entries = pending_changes()
  if #entries == 0 then
    return
  end

  if M.config.watcher.auto_accept then
    M.accept_all_watcher_changes()
    return
  end

  if not M.config.watcher.notify_pending then
    return
  end

  local signature = pending_signature(entries)
  if signature == watcher_state.last_notice_key then
    return
  end

  watcher_state.last_notice_key = signature
  vim.notify(
    ("watcher: %d pending change(s). Use <leader>uj or <C-j> in a Codex float."):format(#entries),
    vim.log.levels.INFO
  )
end

function M.attach_watcher(mod)
  mod = mod or watcher()
  if not mod then
    return
  end

  watcher_state.module = mod
  if not watcher_state.original_review then
    watcher_state.original_review = mod.review
  end

  mod.review = function()
    return M.handle_watcher_review()
  end
end

function M.toggle_watcher_auto_accept()
  M.config.watcher.auto_accept = not M.config.watcher.auto_accept
  vim.notify(
    "watcher auto-accept " .. (M.config.watcher.auto_accept and "enabled" or "disabled"),
    vim.log.levels.INFO
  )

  if M.config.watcher.auto_accept then
    M.handle_watcher_review()
  end
end

local function toggle_auto_accept_from_dashboard()
  M.toggle_watcher_auto_accept()
  refresh_dashboard(dashboard_view)
end

function M.dashboard(view)
  dashboard_view = view or dashboard_view or "overview"

  local builders = {
    overview = overview_lines,
    sessions = sessions_lines,
    changes = changes_lines,
  }
  local build = builders[dashboard_view] or overview_lines
  local lines = build()

  if redraw_dashboard(lines) then
    return
  end

  dashboard_win, dashboard_buf = require("foldfloat").open({
    lines = lines,
    title = DASHBOARD_TITLE,
    section_pattern = "^## ",
    keymaps = {
      extra = {
        { "<C-j>", function() switch_dashboard(1) end, "Codex: next dashboard tab" },
        { "<C-k>", function() switch_dashboard(-1) end, "Codex: previous dashboard tab" },
        { "<CR>", open_selected_dashboard_item, "Codex: open selected item" },
        { "o", open_selected_dashboard_item, "Codex: open selected item" },
        { "a", function() act_selected_change("accept") end, "Watcher: accept selected change" },
        { "r", function() act_selected_change("reject") end, "Watcher: reject selected change" },
        { "x", function() act_selected_change("dismiss") end, "Watcher: dismiss selected change" },
        { "A", function()
          M.accept_all_watcher_changes()
          refresh_dashboard("changes")
        end, "Watcher: accept all changes" },
        { "T", toggle_auto_accept_from_dashboard, "Watcher: toggle auto-accept" },
      },
    },
  })
  vim.b[dashboard_buf].codex_dashboard = true
end

function M.overview()
  M.dashboard("overview")
end

function M.sessions()
  M.dashboard("sessions")
end

function M.changes()
  M.dashboard("changes")
end

return M
