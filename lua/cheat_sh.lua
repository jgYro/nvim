------------------
--
--
-- cheat.sh lookup helper
--
--
------------------

local M = {}

local defaults = {
  base_url = "https://cheat.sh",
  curl = "curl",
  timeout = 15,
}

local config = vim.deepcopy(defaults)

local ft_alias = {
  javascriptreact = "javascript",
  sh = "bash",
  typescriptreact = "typescript",
  zsh = "bash",
}

local extension_alias = {
  cjs = "javascript",
  h = "c",
  hpp = "cpp",
  js = "javascript",
  jsx = "javascript",
  mjs = "javascript",
  py = "python",
  rb = "ruby",
  rs = "rust",
  ts = "typescript",
  tsx = "typescript",
}

local markdown_alias = {
  javascriptreact = "javascript",
  js = "javascript",
  jsx = "javascript",
  sh = "bash",
  shell = "bash",
  typescriptreact = "typescript",
  ts = "typescript",
  tsx = "typescript",
  zsh = "bash",
}

local known_language = {
  bash = true,
  c = true,
  clojure = true,
  cpp = true,
  css = true,
  dart = true,
  dockerfile = true,
  elixir = true,
  erlang = true,
  go = true,
  html = true,
  java = true,
  javascript = true,
  json = true,
  kotlin = true,
  lua = true,
  make = true,
  markdown = true,
  nim = true,
  perl = true,
  php = true,
  python = true,
  r = true,
  ruby = true,
  rust = true,
  scala = true,
  sql = true,
  swift = true,
  typescript = true,
  vim = true,
  yaml = true,
  zig = true,
}

local function trim(value)
  return vim.trim(value or "")
end

local function normalize_filetype(ft)
  ft = trim(ft)
  if ft == "" then
    return nil
  end
  return ft_alias[ft] or ft
end

local function buffer_language()
  local ft = normalize_filetype(vim.bo.filetype)
  if ft then
    return ft
  end

  local ext = trim(vim.fn.expand("%:e")):lower()
  if ext == "" then
    return nil
  end
  return extension_alias[ext] or ext
end

local function encode_query(query)
  local encoded = trim(query):gsub("%s+", "+")
  encoded = encoded:gsub("[^%w%-%._~/%+]", function(char)
    return ("%%%02X"):format(char:byte())
  end)
  return encoded
end

local function query_url(query)
  return ("%s/%s?T"):format(config.base_url:gsub("/+$", ""), encode_query(query))
end

local function split_lines(text)
  text = (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  if text == "" then
    return { "(empty response)" }
  end

  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return #lines > 0 and lines or { "(empty response)" }
end

local function strip_ansi(text)
  text = (text or ""):gsub("\27%]%d+;[^\7]*\7", "")
  text = text:gsub("\27%[[%d;?]*[ -/]*[@-~]", "")
  return text
end

local function markdown_language(language)
  language = normalize_filetype(language)
  if not language then
    return nil
  end
  return markdown_alias[language] or language
end

local function query_language(query)
  query = trim(query):lower()
  local language = query:match("^([%w_%.%-]+)%s*/")
  if language then
    return markdown_language(language)
  end

  language = markdown_language(query:match("^([%w_%.%-]+)"))
  if language and known_language[language] then
    return language
  end
end

local function comment_text(line)
  local stripped = trim(line)
  if stripped == "" or stripped:match("^#!") then
    return nil
  end

  local text = stripped:match("^#%s+(.+)$")
    or stripped:match("^//%s+(.+)$")
    or stripped:match("^%-%-%s+(.+)$")
    or stripped:match("^;%s+(.+)$")
    or stripped:match('^"%s+(.+)$')
    or stripped:match("^/%*+%s*(.-)%s*%*/$")
    or stripped:match("^/%*+%s+(.+)$")
    or stripped:match("^%*%s+(.+)$")
    or stripped:match("^(.-)%s*%*/$")

  text = trim(text)
  if text == "" then
    return nil
  end
  return text
end

local function plain_prose_line(line)
  line = trim(line)
  line = line:gsub("^>+%s*", "")
  line = line:gsub("^[-*]%s+", "")
  line = line:gsub("^%d+%.%s+", "")
  line = line:gsub("!%[([^%]]*)%]%[%d+%]", "Image: %1")
  line = line:gsub("!%[([^%]]*)%]%b()", "Image: %1")
  line = line:gsub("%[([^%]]+)%]%[%d+%]", "%1")
  line = line:gsub("%[([^%]]+)%]%b()", "%1")
  line = line:gsub("%*%*([^%*]+)%*%*", "%1")
  line = line:gsub("%*([^%*]+)%*", "%1")
  line = line:gsub("%*", "")
  line = line:gsub("`([^`]+)`", "%1")
  line = line:gsub("%s+", " ")
  return trim(line)
end

local function reflow_prose(lines)
  local out = {}
  local paragraph = {}

  local function flush()
    if #paragraph == 0 then
      return
    end

    out[#out + 1] = table.concat(paragraph, " ")
    paragraph = {}
  end

  for _, line in ipairs(lines) do
    if line == "" then
      flush()
      if out[#out] ~= "" then
        out[#out + 1] = ""
      end
    else
      paragraph[#paragraph + 1] = line
    end
  end

  flush()

  while out[1] ~= nil and out[1] == "" do
    table.remove(out, 1)
  end
  while out[#out] ~= nil and out[#out] == "" do
    table.remove(out)
  end

  return out
end

local function clean_block_comment(lines)
  local prose = {}
  local drop_reference_continuation = false
  for index, line in ipairs(lines) do
    if index == 1 then
      line = line:gsub("^%s*/%*+%s*", "")
    end
    line = line:gsub("%s*%*/%s*$", "")
    line = line:gsub("^%s*%*%s?", "")

    local plain = plain_prose_line(line)
    if plain == "" then
      drop_reference_continuation = false
      prose[#prose + 1] = ""
    elseif plain:match("^%[%d+%]:") then
      drop_reference_continuation = true
    elseif drop_reference_continuation and plain:match("^[%w%-%._/:]+$") then
      -- Wrapped URL continuation from a dropped markdown reference.
    elseif
      not plain:match("^<!%-%-%s*language%-all:")
      and not plain:match("^%[[^%]]+%]%s+%[[^%]]+%]")
      and not plain:match("^%-%-%-%-+$")
    then
      drop_reference_continuation = false
      prose[#prose + 1] = plain
    end
  end

  return reflow_prose(prose)
end

local function section_title(lines)
  local fallback = nil
  for _, line in ipairs(lines) do
    local title = plain_prose_line(line)
    if title ~= "" and not title:match("^%[%d+%]:") and not title:match("^!?%[.-%]%[?%d*%]?") then
      if #title > 72 then
        title = title:sub(1, 69):gsub("%s+$", "") .. "..."
      end
      if title ~= "" then
        if not fallback then
          fallback = title
        end
        if line:match("^%s*>") or title:match("%?$") then
          return title
        end
      end
    end
  end

  return fallback or "Notes"
end

local function append_blank(lines)
  if lines[#lines] ~= "" then
    lines[#lines + 1] = ""
  end
end

local function render_response(query, output)
  local language = query_language(query) or "bash"
  local rendered = {
    ("# cheat.sh: `%s`"):format(query),
    "",
  }
  local code = {}
  local section_open = false

  local function flush_code()
    if #code == 0 then
      return
    end

    append_blank(rendered)
    rendered[#rendered + 1] = ("```%s"):format(language)
    vim.list_extend(rendered, code)
    rendered[#rendered + 1] = "```"
    rendered[#rendered + 1] = ""
    code = {}
  end

  local function open_section(title)
    append_blank(rendered)
    rendered[#rendered + 1] = "## " .. title
    rendered[#rendered + 1] = ""
    section_open = true
  end

  local function append_prose_section(lines)
    if #lines == 0 then
      return
    end

    open_section(section_title(lines))
    vim.list_extend(rendered, lines)
    rendered[#rendered + 1] = ""
  end

  local code_started_in_block = false
  local lines = split_lines(strip_ansi(output))
  local index = 1
  while index <= #lines do
    local line = lines[index]
    local stripped = trim(line)

    if line:match("^/%*") then
      flush_code()
      local block = {}
      repeat
        block[#block + 1] = lines[index] or ""
        if trim(lines[index] or ""):match("%*/%s*$") then
          break
        end
        index = index + 1
      until index > #lines

      append_prose_section(clean_block_comment(block))
      code_started_in_block = false
    elseif stripped == "" then
      flush_code()
      append_blank(rendered)
      code_started_in_block = false
    else
      local prose = not code_started_in_block and comment_text(line)
      if prose then
        flush_code()
        open_section(prose)
        code_started_in_block = false
      else
        if not section_open then
          open_section("Result")
        end
        code_started_in_block = true
        code[#code + 1] = line
      end
    end

    index = index + 1
  end

  flush_code()
  while #rendered > 1 and rendered[#rendered] == "" do
    table.remove(rendered)
  end

  return rendered
end

local function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function open_fallback(query, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = clamp(math.floor(vim.o.columns * 0.82), 50, math.max(20, vim.o.columns - 6))
  local height = clamp(math.floor((vim.o.lines - vim.o.cmdheight) * 0.72), 12, math.max(6, vim.o.lines - 6))
  local row = math.floor((vim.o.lines - vim.o.cmdheight - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = (" cheat.sh: %s "):format(query),
    title_pos = "center",
  })

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true, desc = "Close cheat.sh" })
  vim.keymap.set("n", "<C-o>", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true, desc = "Close cheat.sh" })
end

local function open_result(query, output)
  local lines = render_response(query, output)
  local ok, foldfloat = pcall(require, "foldfloat")
  if ok then
    foldfloat.open({
      lines = lines,
      title = ("cheat.sh: %s  ·  <Tab> fold  ·  n/p open  ·  <C-n>/<C-p> move  ·  q close"):format(query),
      section_pattern = "^## ",
      width = 0.84,
      height = 0.78,
    })
    return
  end

  open_fallback(query, lines)
end

local function show_error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function run_curl(query)
  local url = query_url(query)
  vim.notify(("cheat.sh: %s"):format(query), vim.log.levels.INFO)

  if vim.system then
    vim.system({ config.curl, "-fsSL", "--max-time", tostring(config.timeout), url }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          local stderr = trim(result.stderr)
          show_error(stderr ~= "" and ("cheat.sh failed: " .. stderr) or "cheat.sh request failed")
          return
        end
        open_result(query, result.stdout)
      end)
    end)
    return
  end

  local stdout = {}
  local stderr = {}
  local job = vim.fn.jobstart({ config.curl, "-fsSL", "--max-time", tostring(config.timeout), url }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          local message = trim(table.concat(stderr, "\n"))
          show_error(message ~= "" and ("cheat.sh failed: " .. message) or "cheat.sh request failed")
          return
        end
        open_result(query, table.concat(stdout, "\n"))
      end)
    end,
  })

  if job <= 0 then
    show_error("cheat.sh failed to start curl")
  end
end

local function query_has_scope(query)
  return query:match("^/?[%w_%.%-]+/") ~= nil
end

local function scoped_query(query)
  query = trim(query)
  if query == "" or query_has_scope(query) then
    return query
  end

  local language = buffer_language()
  return language and ("%s/%s"):format(language, query) or query
end

function M.query(query, opts)
  opts = opts or {}
  query = trim(query)
  if query == "" then
    M.prompt()
    return
  end

  if opts.infer_language then
    query = scoped_query(query)
  end

  run_curl(query)
end

function M.prompt()
  vim.ui.input({ prompt = "cheat.sh query: " }, function(input)
    if input then
      M.query(input, { infer_language = true })
    end
  end)
end

function M.word()
  local word = trim(vim.fn.expand("<cword>"))
  if word == "" then
    M.prompt()
    return
  end

  local language = buffer_language()
  M.query(language and ("%s/%s"):format(language, word) or word)
end

function M.filetype()
  local language = buffer_language()
  if not language then
    vim.notify("cheat.sh: current buffer has no filetype", vim.log.levels.WARN)
    M.prompt()
    return
  end

  M.query(language)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("Cheat", function(command)
    M.query(command.args)
  end, {
    nargs = "*",
    desc = "Query cheat.sh",
  })

  vim.api.nvim_create_user_command("CheatWord", M.word, {
    desc = "Query cheat.sh for the word under cursor",
  })

  vim.api.nvim_create_user_command("CheatFiletype", M.filetype, {
    desc = "Query cheat.sh for the current filetype",
  })
end

return M
