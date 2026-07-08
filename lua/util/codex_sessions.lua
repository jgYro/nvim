local M = {}

local DEFAULT_IDLE_MS = 1200
local ASK_FLASH_MS = 7000
local DONE_FLASH_MS = 5000
local FOCUS_ACTIVITY_SUPPRESS_MS = 250
local INPUT_ECHO_SUPPRESS_MS = 350
local INPUT_SUBMIT_ECHO_SUPPRESS_MS = 120
local INPUT_TAIL_LINES = 12
local VIEW_ORDER = { "terminal", "overview", "sessions", "changes" }

M.config = {
  cmd = "codex",
  notify = {
    completed = true,
    input = true,
  },
  status = {
    idle_ms = DEFAULT_IDLE_MS,
  },
  watcher = {
    auto_accept = true,
    intercept_review = true,
    notify_pending = true,
  },
}

local sessions = {}
local current_index = nil
local next_id = 0
local header_ns = vim.api.nvim_create_namespace("codex_sessions_header")
local input_ns = vim.api.nvim_create_namespace("codex_sessions_input")
local input_hook_attached = false
local render_queued = false
local session_palette = {
  { name = "blue", fg = "#0f172a", bg = "#60a5fa" },
  { name = "green", fg = "#052e16", bg = "#4ade80" },
  { name = "yellow", fg = "#422006", bg = "#facc15" },
  { name = "magenta", fg = "#3b0764", bg = "#e879f9" },
  { name = "cyan", fg = "#083344", bg = "#22d3ee" },
  { name = "red", fg = "#450a0a", bg = "#f87171" },
}

local workspace = {
  view = "terminal",
  header_buf = nil,
  header_win = nil,
  body_buf = nil,
  body_win = nil,
  origin_win = nil,
}

local watcher_state = {
  module = nil,
  original_review = nil,
  last_notice_key = nil,
}

local uv = vim.uv or vim.loop

local function now()
  return uv.now()
end

local function idle_ms()
  local value = tonumber(M.config.status and M.config.status.idle_ms) or DEFAULT_IDLE_MS
  return math.floor(math.max(250, value))
end

local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function relpath(path)
  return vim.fn.fnamemodify(path, ":.")
end

local function command_label(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end

  return cmd
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

local function current_session()
  local index = find_index_by_buf(vim.api.nvim_get_current_buf())
  return index and sessions[index] or nil
end

local function session_label(session)
  return tostring(session.id)
end

local function status_for(session)
  if session.exited then
    return "exited"
  end
  if session.needs_input then
    return "asking"
  end
  return session.state or "completed"
end

local complete_session
local request_header_render
local schedule_idle_check
local stop_idle_timer
local update_input_state

local function reconcile_session_statuses()
  local current = now()
  for _, session in ipairs(sessions) do
    if
      not session.exited
      and session.state == "busy"
      and session.last_activity
      and current - session.last_activity >= idle_ms()
    then
      if update_input_state then
        update_input_state(session)
      end
      if not session.needs_input then
        complete_session(session, { render = false })
      end
    end
  end
end

local function title_case(value)
  return (value:gsub("^%l", string.upper))
end

local function session_hl_group(session)
  return "CodexSession" .. title_case(session.color.name)
end

local function active_flash(session, kind)
  return session.flash_kind == kind and session.flash_until and now() < session.flash_until
end

local function session_is_busy(session)
  return not session.exited and not session.needs_input and session.state == "busy"
end

local function suppress_focus_activity(session)
  if not session.started or session_is_busy(session) then
    return
  end

  session.suppress_activity_until = now() + FOCUS_ACTIVITY_SUPPRESS_MS
end

local function key_submits_terminal_input(key)
  return key == "\r" or key == "\n" or key == vim.keycode("<CR>")
end

local function ensure_input_hook()
  if input_hook_attached then
    return
  end

  input_hook_attached = true
  vim.on_key(function(key)
    local mode = vim.api.nvim_get_mode().mode
    if mode:sub(1, 1) ~= "t" then
      return
    end

    local session = current_session()
    if session and session.started and not session.exited then
      local suppress_ms = key_submits_terminal_input(key) and INPUT_SUBMIT_ECHO_SUPPRESS_MS or INPUT_ECHO_SUPPRESS_MS
      session.input_echo_suppress_until = now() + suppress_ms
    end
  end, input_ns)
end

local function session_header_hl_group(session)
  if session.needs_input or active_flash(session, "ask") then
    return "CodexSessionAsk"
  end
  if session_is_busy(session) then
    return "CodexSessionBusy"
  end
  if active_flash(session, "done") then
    return "CodexSessionDone"
  end
  return session_hl_group(session)
end

local function ensure_header_highlights()
  vim.api.nvim_set_hl(0, "CodexSessionAsk", { fg = "#422006", bg = "#facc15", bold = true })
  vim.api.nvim_set_hl(0, "CodexSessionBusy", { fg = "#450a0a", bg = "#f87171", bold = true })
  vim.api.nvim_set_hl(0, "CodexSessionDone", { fg = "#052e16", bg = "#a3e635", bold = true })
  for _, color in ipairs(session_palette) do
    vim.api.nvim_set_hl(0, "CodexSession" .. title_case(color.name), {
      fg = color.fg,
      bg = color.bg,
      bold = true,
    })
  end
end

local function overview_counts()
  reconcile_session_statuses()
  local counts = { asking = 0, busy = 0, completed = 0, exited = 0 }
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

local function flash_session(session, kind, duration_ms)
  session.flash_kind = kind
  session.flash_until = now() + duration_ms
  session.flash_seq = (session.flash_seq or 0) + 1
  local seq = session.flash_seq

  vim.defer_fn(function()
    if session.flash_seq == seq and session.flash_until and now() >= session.flash_until then
      session.flash_kind = nil
      session.flash_until = nil
      request_header_render()
    end
  end, duration_ms)
end

request_header_render = function()
  if render_queued then
    return
  end

  render_queued = true
  vim.schedule(function()
    render_queued = false
    M.render_header()
  end)
end

stop_idle_timer = function(session, close)
  if not session.idle_timer then
    return
  end

  pcall(session.idle_timer.stop, session.idle_timer)
  if close then
    pcall(session.idle_timer.close, session.idle_timer)
    session.idle_timer = nil
  end
end

schedule_idle_check = function(session)
  if session.exited then
    return
  end

  if not session.idle_timer then
    session.idle_timer = uv.new_timer()
  end

  stop_idle_timer(session, false)
  session.idle_timer:start(idle_ms(), 0, function()
    vim.schedule(function()
      if session.exited or not (session.state == "busy" or session.state == "asking") then
        return
      end
      if update_input_state then
        update_input_state(session)
      end
      complete_session(session)
    end)
  end)
end

local function notify_once(session, key, message, level)
  if session.notice_key == key then
    return
  end
  session.notice_key = key
  vim.notify(message, level)
end

local function clean_terminal_line(line)
  line = line:gsub("\27%[[%d;?]*[ -/]*[@-~]", "")
  line = line:gsub("\r", "")
  return vim.trim(line)
end

local function line_requests_input(line)
  local lower = line:lower()
  local explicit_patterns = {
    "%[y/n%]",
    "%(y/n%)",
    "%[yes/no%]",
    "%(yes/no%)",
  }
  for _, pattern in ipairs(explicit_patterns) do
    if lower:match(pattern) then
      return true
    end
  end

  local explicit_phrases = {
    "approval required",
    "awaiting input",
    "choose an option",
    "press enter",
    "press return",
    "select an option",
    "user input required",
    "waiting for input",
  }
  for _, phrase in ipairs(explicit_phrases) do
    if lower:find(phrase, 1, true) then
      return true
    end
  end

  if not lower:find("?", 1, true) then
    return false
  end

  local question_phrases = {
    "allow",
    "approve",
    "can i",
    "continue",
    "do you want",
    "may i",
    "proceed",
    "should i",
    "would you like",
  }
  for _, phrase in ipairs(question_phrases) do
    if lower:find(phrase, 1, true) then
      return true
    end
  end

  return false
end

local function terminal_input_request(session)
  if not valid_buf(session.buf) then
    return false, nil
  end

  local line_count = vim.api.nvim_buf_line_count(session.buf)
  local start = math.max(0, line_count - 200)
  local lines = vim.api.nvim_buf_get_lines(session.buf, start, line_count, false)
  local seen = 0
  for i = #lines, 1, -1 do
    local line = clean_terminal_line(lines[i] or "")
    if line ~= "" then
      seen = seen + 1
      if line_requests_input(line) then
        return true, line
      end
      if seen >= INPUT_TAIL_LINES then
        break
      end
    end
  end

  return false, nil
end

update_input_state = function(session)
  if session.exited then
    return false
  end

  local asking, line = terminal_input_request(session)
  if asking then
    local changed = not session.needs_input
    session.needs_input = true
    session.state = "asking"
    flash_session(session, "ask", ASK_FLASH_MS)

    if M.config.notify.input ~= false then
      notify_once(
        session,
        "input:" .. line,
        ("Codex session %s is asking for input"):format(session_label(session)),
        vim.log.levels.WARN
      )
    end

    return changed
  end

  if session.needs_input then
    session.needs_input = false
    if session.state == "asking" then
      session.state = "busy"
    end
    return true
  end

  return false
end

complete_session = function(session, opts)
  opts = opts or {}
  if session.exited or session.needs_input or session.state == "completed" then
    return
  end

  stop_idle_timer(session, false)
  session.state = "completed"
  session.completed_at = now()
  flash_session(session, "done", DONE_FLASH_MS)

  if M.config.notify.completed ~= false then
    notify_once(
      session,
      ("completed:%d"):format(session.activity_seq),
      ("Codex session %s completed"):format(session_label(session)),
      vim.log.levels.INFO
    )
  end

  if opts.render ~= false then
    request_header_render()
  end
end

local function mark_busy(session)
  if session.exited then
    return
  end

  if session.input_echo_suppress_until then
    if now() < session.input_echo_suppress_until then
      return
    end
    session.input_echo_suppress_until = nil
  end

  if session.suppress_activity_until then
    if now() < session.suppress_activity_until then
      return
    end
    session.suppress_activity_until = nil
  end

  local previous_status = status_for(session)
  session.last_activity = now()
  session.activity_seq = session.activity_seq + 1
  session.completed_at = nil

  if update_input_state then
    update_input_state(session)
  end

  if not session.needs_input then
    session.state = "busy"
  end

  schedule_idle_check(session)

  if status_for(session) ~= previous_status then
    request_header_render()
  end
end

local function mark_exited(session, code)
  stop_idle_timer(session, true)
  session.exited = true
  session.state = "exited"
  session.needs_input = false
  session.exit_code = code
  session.job_id = nil
  session.last_activity = now()
  session.activity_seq = session.activity_seq + 1
  request_header_render()
end

local function configure_header_buf(buf)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].swapfile = false
end

local function configure_body_buf(buf, filetype)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = filetype or "markdown"
  vim.bo[buf].swapfile = false
end

local function configure_workspace_win(win, is_header)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = not is_header
  vim.wo[win].cursorline = not is_header
  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
end

local function workspace_geometry()
  local columns = vim.o.columns
  local lines = math.max(1, vim.o.lines - vim.o.cmdheight - 1)
  local width = math.min(math.max(1, columns - 4), math.floor(columns * 0.9))
  local total_height = math.min(math.max(8, lines - 2), math.floor(lines * 0.85))
  local header_height = 1
  local body_height = math.max(5, total_height - header_height)
  local col = math.floor((columns - width) / 2)
  local row = math.floor((lines - total_height) / 2)

  return {
    header = {
      relative = "editor",
      width = width,
      height = header_height,
      col = col,
      row = row,
      style = "minimal",
      zindex = 50,
    },
    body = {
      relative = "editor",
      width = width,
      height = body_height,
      col = col,
      row = row + header_height,
      style = "minimal",
      border = "rounded",
      title = " Codex workspace ",
      title_pos = "center",
      zindex = 50,
    },
  }
end

local function workspace_visible()
  return valid_win(workspace.header_win) and valid_win(workspace.body_win)
end

local function is_workspace_win(win)
  return win == workspace.header_win or win == workspace.body_win
end

local function remember_origin_win()
  local win = vim.api.nvim_get_current_win()
  if not is_workspace_win(win) and vim.api.nvim_win_get_config(win).relative == "" then
    workspace.origin_win = win
  end
end

local function focus_origin_win()
  if valid_win(workspace.origin_win) then
    vim.api.nvim_set_current_win(workspace.origin_win)
    return true
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if valid_win(win) and vim.api.nvim_win_get_config(win).relative == "" then
      vim.api.nvim_set_current_win(win)
      workspace.origin_win = win
      return true
    end
  end

  return false
end

local function ensure_workspace()
  local geometry = workspace_geometry()

  remember_origin_win()

  if not valid_buf(workspace.header_buf) then
    workspace.header_buf = vim.api.nvim_create_buf(false, true)
    configure_header_buf(workspace.header_buf)
  end

  if not valid_buf(workspace.body_buf) then
    workspace.body_buf = vim.api.nvim_create_buf(false, true)
    configure_body_buf(workspace.body_buf, "markdown")
    vim.b[workspace.body_buf].codex_workspace_body = true
  end

  if valid_win(workspace.header_win) then
    vim.api.nvim_win_set_config(workspace.header_win, geometry.header)
  else
    workspace.header_win = vim.api.nvim_open_win(workspace.header_buf, false, geometry.header)
  end

  if valid_win(workspace.body_win) then
    vim.api.nvim_win_set_config(workspace.body_win, geometry.body)
  else
    workspace.body_win = vim.api.nvim_open_win(workspace.body_buf, true, geometry.body)
  end

  configure_workspace_win(workspace.header_win, true)
  configure_workspace_win(workspace.body_win, false)
  return workspace.header_win, workspace.body_win
end

local function close_workspace()
  if valid_win(workspace.header_win) then
    pcall(vim.api.nvim_win_close, workspace.header_win, true)
  end
  if valid_win(workspace.body_win) then
    pcall(vim.api.nvim_win_close, workspace.body_win, true)
  end
  workspace.header_win = nil
  workspace.body_win = nil
  focus_origin_win()
end

local function set_lines(buf, lines, filetype)
  configure_body_buf(buf, filetype or "markdown")
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function view_index(view)
  for i, candidate in ipairs(VIEW_ORDER) do
    if candidate == view then
      return i
    end
  end
  return 1
end

local function tab_line()
  local parts = {}
  local changes = #pending_changes()

  for _, view in ipairs(VIEW_ORDER) do
    local label = view
    if view == "sessions" then
      label = ("sess:%d"):format(#sessions)
    elseif view == "changes" then
      label = ("chg:%d"):format(changes)
    elseif view == "terminal" and current_index and sessions[current_index] then
      label = "term:" .. session_label(sessions[current_index])
    end

    if view == workspace.view then
      parts[#parts + 1] = "[" .. label .. "]"
    else
      parts[#parts + 1] = label
    end
  end

  return table.concat(parts, "  ")
end

function M.render_header()
  if not valid_buf(workspace.header_buf) then
    return
  end

  ensure_header_highlights()
  reconcile_session_statuses()
  local changes = #pending_changes()
  local parts = {}
  local spans = {}
  local col = 0

  local function append(text)
    parts[#parts + 1] = text
    col = col + #text
  end

  local function append_session(session, text, hl_group)
    local start_col = col
    append(text)
    local label = session_label(session)
    local offset = text:find(label, 1, true)
    if offset then
      spans[#spans + 1] = {
        start_col + offset - 1,
        start_col + offset - 1 + #label,
        hl_group or session_header_hl_group(session),
      }
    end
  end

  append("  " .. tab_line() .. " | ")

  if #sessions == 0 then
    append("sessions:none")
  else
    append("sessions:")
    for i, session in ipairs(sessions) do
      if i > 1 then
        append(" ")
      end
      local label = session_label(session)
      append_session(session, i == current_index and ("[" .. label .. "]") or label)
    end
  end

  local asking = {}
  local busy = {}
  local done = {}
  for _, session in ipairs(sessions) do
    if session.needs_input then
      asking[#asking + 1] = session
    elseif session_is_busy(session) then
      busy[#busy + 1] = session
    elseif active_flash(session, "done") then
      done[#done + 1] = session
    end
  end

  if #busy > 0 then
    append(" | busy:")
    for i, session in ipairs(busy) do
      if i > 1 then
        append(",")
      end
      append_session(session, session_label(session), "CodexSessionBusy")
    end
  end

  if #asking > 0 then
    append(" | ask:")
    for i, session in ipairs(asking) do
      if i > 1 then
        append(",")
      end
      append_session(session, session_label(session), "CodexSessionAsk")
    end
  end

  if #done > 0 then
    append(" | done:")
    for i, session in ipairs(done) do
      if i > 1 then
        append(",")
      end
      append_session(session, session_label(session), "CodexSessionDone")
    end
  end

  append(
    (" | chg:%d auto:%s | C-h/l sess C-j/k view C-o back"):format(
      changes,
      M.config.watcher.auto_accept and "on" or "off"
    )
  )

  local line = table.concat(parts)
  vim.bo[workspace.header_buf].modifiable = true
  vim.api.nvim_buf_set_lines(workspace.header_buf, 0, -1, false, { line })
  vim.bo[workspace.header_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(workspace.header_buf, header_ns, 0, -1)

  for _, span in ipairs(spans) do
    vim.api.nvim_buf_add_highlight(workspace.header_buf, header_ns, span[3], 0, span[1], span[2])
  end
end

local function configure_view_maps(buf)
  if vim.b[buf].codex_workspace_maps then
    return
  end
  vim.b[buf].codex_workspace_maps = true

  vim.keymap.set("n", "q", close_workspace, { buffer = buf, nowait = true, silent = true, desc = "Codex: close workspace" })
  vim.keymap.set("n", "<C-o>", close_workspace, { buffer = buf, nowait = true, silent = true, desc = "Codex: return to main buffer" })
  vim.keymap.set("n", "<C-j>", M.next_view, { buffer = buf, nowait = true, silent = true, desc = "Codex: next view" })
  vim.keymap.set("n", "<C-k>", M.prev_view, { buffer = buf, nowait = true, silent = true, desc = "Codex: previous view" })
  vim.keymap.set("n", "<C-l>", M.next, { buffer = buf, nowait = true, silent = true, desc = "Codex: next session" })
  vim.keymap.set("n", "<C-h>", M.prev, { buffer = buf, nowait = true, silent = true, desc = "Codex: previous session" })
  vim.keymap.set("n", "<CR>", M.open_selected, { buffer = buf, nowait = true, silent = true, desc = "Codex: open selected item" })
  vim.keymap.set("n", "o", M.open_selected, { buffer = buf, nowait = true, silent = true, desc = "Codex: open selected item" })
  vim.keymap.set("n", "a", function()
    M.act_selected_change("accept")
  end, { buffer = buf, nowait = true, silent = true, desc = "Watcher: accept selected change" })
  vim.keymap.set("n", "r", function()
    M.act_selected_change("reject")
  end, { buffer = buf, nowait = true, silent = true, desc = "Watcher: reject selected change" })
  vim.keymap.set("n", "x", function()
    M.act_selected_change("dismiss")
  end, { buffer = buf, nowait = true, silent = true, desc = "Watcher: dismiss selected change" })
  vim.keymap.set("n", "A", function()
    M.accept_all_watcher_changes()
    M.show_view("changes")
  end, { buffer = buf, nowait = true, silent = true, desc = "Watcher: accept all changes" })
  vim.keymap.set("n", "T", function()
    M.toggle_watcher_auto_accept()
    M.show_view(workspace.view)
  end, { buffer = buf, nowait = true, silent = true, desc = "Watcher: toggle auto-accept" })
end

local function configure_session_buffer(session)
  local buf = session.buf
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.b[buf].codex_session_id = session.id

  if vim.b[buf].codex_session_maps then
    return
  end
  vim.b[buf].codex_session_maps = true

  vim.keymap.set("n", "q", close_workspace, { buffer = buf, nowait = true, silent = true, desc = "Codex: close workspace" })
  vim.keymap.set("n", "<C-o>", close_workspace, { buffer = buf, nowait = true, silent = true, desc = "Codex: return to main buffer" })
  vim.keymap.set("t", "<C-o>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').close()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: return to main buffer",
  })
  vim.keymap.set("n", "<C-l>", M.next, { buffer = buf, nowait = true, silent = true, desc = "Codex: next session" })
  vim.keymap.set("t", "<C-l>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').next()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: next session",
  })
  vim.keymap.set("n", "<C-h>", M.prev, { buffer = buf, nowait = true, silent = true, desc = "Codex: previous session" })
  vim.keymap.set("t", "<C-h>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').prev()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: previous session",
  })
  vim.keymap.set("n", "<C-j>", M.next_view, { buffer = buf, nowait = true, silent = true, desc = "Codex: next view" })
  vim.keymap.set("t", "<C-j>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').next_view()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: next view",
  })
  vim.keymap.set("n", "<C-k>", M.prev_view, { buffer = buf, nowait = true, silent = true, desc = "Codex: previous view" })
  vim.keymap.set("t", "<C-k>", "<C-\\><C-n><cmd>lua require('util.codex_sessions').prev_view()<cr>", {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Codex: previous view",
  })
end

local function attach_activity(session)
  pcall(vim.api.nvim_buf_attach, session.buf, false, {
    on_lines = function(_, changed_buf)
      if changed_buf == session.buf then
        vim.schedule(function()
          if session.buf == changed_buf then
            mark_busy(session)
          end
        end)
      end
    end,
    on_detach = function(_, detached_buf)
      if detached_buf == session.buf then
        session.buf = nil
      end
    end,
  })
end

local function make_session()
  local id = next_id
  next_id = next_id + 1

  local session = {
    id = id,
    color = session_palette[(id % #session_palette) + 1],
    key = ("codex:%d"):format(id),
    cwd = vim.fn.getcwd(),
    state = "busy",
    created_at = now(),
    completed_at = nil,
    last_activity = nil,
    activity_seq = 0,
    flash_kind = nil,
    flash_seq = 0,
    flash_until = nil,
    buf = vim.api.nvim_create_buf(false, true),
    job_id = nil,
    exit_code = nil,
    exited = false,
    needs_input = false,
    notice_key = nil,
    started = false,
    input_echo_suppress_until = nil,
    suppress_activity_until = nil,
  }

  ensure_input_hook()
  configure_session_buffer(session)
  attach_activity(session)
  table.insert(sessions, session)
  return session, #sessions
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
  local id = tonumber(heading:match("^session (%d+)"))
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

local function overview_lines()
  local counts = overview_counts()
  local changes = #pending_changes()
  local lines = {
    "# Overview",
    "",
    "## Sessions",
    "",
    ("- total: %d"):format(#sessions),
    ("- asking: %d"):format(counts.asking or 0),
    ("- busy: %d"):format(counts.busy or 0),
    ("- completed: %d"):format(counts.completed or 0),
    ("- exited: %d"):format(counts.exited or 0),
  }

  if current_index and sessions[current_index] then
    lines[#lines + 1] = ("- current: %s"):format(session_label(sessions[current_index]))
  else
    lines[#lines + 1] = "- current: none"
  end

  vim.list_extend(lines, {
    "",
    "## Changes",
    "",
    ("- pending files: %d"):format(changes),
    ("- auto-accept: %s"):format(M.config.watcher.auto_accept and "on" or "off"),
    "- source: watcher.nvim pending registry",
    "",
  })

  return lines
end

local function sessions_lines()
  local counts = overview_counts()
  local lines = {
    "# Sessions",
    "",
    ("%d total | %d asking | %d busy | %d completed | %d exited"):format(
      #sessions,
      counts.asking or 0,
      counts.busy or 0,
      counts.completed or 0,
      counts.exited or 0
    ),
    "",
  }

  if #sessions == 0 then
    vim.list_extend(lines, {
      "No Codex sessions yet.",
      "",
      "Use `<leader>uc` to start one, or `<leader>uC` to create another instance.",
    })
    return lines
  end

  for i, session in ipairs(sessions) do
    local flags = {}
    if i == current_index then
      flags[#flags + 1] = "current"
    end
    local suffix = #flags > 0 and (" [" .. table.concat(flags, ", ") .. "]") or ""

    lines[#lines + 1] = ("## session %s [%s]%s"):format(session_label(session), status_for(session), suffix)
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("- cwd: `%s`"):format(session.cwd)
    lines[#lines + 1] = ("- buffer: `%s`"):format(session.buf or "none")
    lines[#lines + 1] = ("- job: `%s`"):format(session.job_id or "none")
    lines[#lines + 1] = ("- created: %s"):format(elapsed(session.created_at))
    lines[#lines + 1] = ("- last output: %s"):format(elapsed(session.last_activity))
    lines[#lines + 1] = ("- completed: %s"):format(elapsed(session.completed_at))
    if session.exited then
      lines[#lines + 1] = ("- exit code: `%s`"):format(session.exit_code or "unknown")
    end
    lines[#lines + 1] = ""
  end

  return lines
end

local function changes_lines()
  local entries = pending_changes()
  local lines = {
    "# Changes",
    "",
    ("Auto-accept is %s. Pending files: %d."):format(M.config.watcher.auto_accept and "on" or "off", #entries),
    "",
  }

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

local function render_body(lines, filetype)
  ensure_workspace()
  configure_view_maps(workspace.body_buf)
  set_lines(workspace.body_buf, lines, filetype or "markdown")
  vim.api.nvim_win_set_buf(workspace.body_win, workspace.body_buf)
  vim.api.nvim_set_current_win(workspace.body_win)
  pcall(vim.api.nvim_win_set_cursor, workspace.body_win, { 1, 0 })
  configure_workspace_win(workspace.body_win, false)
  M.render_header()
end

local function start_session(session)
  if session.started or session.exited then
    return
  end

  vim.api.nvim_set_current_win(workspace.body_win)
  vim.api.nvim_win_set_buf(workspace.body_win, session.buf)
  vim.api.nvim_set_current_buf(session.buf)
  session.started = true

  local cmd = M.config.cmd or "codex"
  local ok, job_id = pcall(vim.fn.jobstart, cmd, {
    term = true,
    cwd = session.cwd,
    on_exit = function(_, code)
      mark_exited(session, code)
    end,
  })

  if not ok or type(job_id) ~= "number" or job_id <= 0 then
    session.started = false
    session.exited = true
    session.state = "exited"
    vim.notify("Failed to start " .. command_label(cmd), vim.log.levels.ERROR)
    M.render_header()
    return
  end

  session.job_id = job_id
  mark_busy(session)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.close()
  close_workspace()
end

function M.show_terminal(index)
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

  current_index = index
  workspace.view = "terminal"
  ensure_workspace()
  suppress_focus_activity(session)
  vim.api.nvim_win_set_buf(workspace.body_win, session.buf)
  configure_workspace_win(workspace.body_win, false)
  start_session(session)
  vim.api.nvim_set_current_win(workspace.body_win)
  M.render_header()

  if not session.exited then
    vim.cmd.startinsert()
  end
end

function M.show_view(view)
  workspace.view = view or workspace.view or "overview"

  if workspace.view == "terminal" then
    M.show_terminal(current_index or active_index())
    return
  end

  local builders = {
    overview = overview_lines,
    sessions = sessions_lines,
    changes = changes_lines,
  }
  local build = builders[workspace.view] or overview_lines
  render_body(build(), "markdown")
end

function M.next_view()
  local next = VIEW_ORDER[(view_index(workspace.view) % #VIEW_ORDER) + 1]
  M.show_view(next)
end

function M.prev_view()
  local prev = VIEW_ORDER[((view_index(workspace.view) - 2) % #VIEW_ORDER) + 1]
  M.show_view(prev)
end

function M.open(index)
  return M.show_terminal(index)
end

function M.toggle_current()
  if workspace_visible() and workspace.view == "terminal" then
    close_workspace()
    return
  end

  return M.show_terminal(current_index or active_index())
end

function M.new()
  local _, index = make_session()
  return M.show_terminal(index)
end

function M.next()
  if #sessions == 0 then
    return M.new()
  end

  local index = active_index()
  return M.show_terminal((index % #sessions) + 1)
end

function M.prev()
  if #sessions == 0 then
    return M.new()
  end

  local index = active_index()
  return M.show_terminal(((index - 2) % #sessions) + 1)
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
  close_workspace()
  vim.schedule(function()
    if not focus_file_window() then
      vim.cmd("tabnew")
    end

    vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
    entry.kind, entry.buf, entry.visited = "buffer", vim.api.nvim_get_current_buf(), true
  end)
end

function M.open_selected()
  if workspace.view == "sessions" then
    local index = selected_session_index()
    if not index then
      vim.notify("No Codex session under cursor", vim.log.levels.WARN)
      return
    end
    M.show_terminal(index)
    return
  end

  if workspace.view == "changes" then
    M.act_selected_change("open")
    return
  end

  local heading = selected_heading() or ""
  if heading:match("^Sessions") then
    M.show_view("sessions")
  elseif heading:match("^Changes") then
    M.show_view("changes")
  end
end

function M.act_selected_change(action)
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
  M.show_view("changes")
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

  M.render_header()

  if not M.config.watcher.notify_pending then
    return
  end

  local signature = pending_signature(entries)
  if signature == watcher_state.last_notice_key then
    return
  end

  watcher_state.last_notice_key = signature
  vim.notify(
    ("watcher: %d pending change(s). Use <leader>uj or C-j in the Codex workspace."):format(#entries),
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
  M.render_header()

  if M.config.watcher.auto_accept then
    M.handle_watcher_review()
  elseif workspace.view == "changes" then
    M.show_view("changes")
  end
end

function M.dashboard(view)
  if view == "overview" or view == "sessions" or view == "changes" or view == "terminal" then
    return M.show_view(view)
  end
  return M.show_view("overview")
end

function M.overview()
  M.show_view("overview")
end

function M.sessions()
  M.show_view("sessions")
end

function M.changes()
  M.show_view("changes")
end

return M
