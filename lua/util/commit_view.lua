------------------
--
--
-- commit_view: render a git commit as a foldfloat popup
--
--
------------------

-- Used by gitsigns' <leader>hc. Builds the commit as markdown -- subject as a
-- heading, a metadata line, the body, then each changed file as its own
-- `### file (+adds -dels)` section with the diff in a ```diff block -- and hands
-- it to foldfloat, which renders the foldable, tabbed-list float (per-file fold
-- rows, <Tab> expand, <C-l>/<C-h> expand/collapse all, n/p between files,
-- q/<Esc>/<C-o> close). The git work lives here; the UI lives in foldfloat.

local M = {}

local function git(dir, args)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

-- Lines git emits between `diff --git` and the actual hunks that are just noise
-- once the filename is a heading (the index/mode/rename/--- /+++ chrome).
local function is_diff_noise(line)
  return line:match("^index ")
    or line:match("^%-%-%- ")
    or line:match("^%+%+%+ ")
    or line:match("^new file mode")
    or line:match("^deleted file mode")
    or line:match("^old mode")
    or line:match("^new mode")
    or line:match("^similarity index")
    or line:match("^dissimilarity index")
    or line:match("^rename from")
    or line:match("^rename to")
    or line:match("^copy from")
    or line:match("^copy to")
end

-- Split a unified patch into { file, add, del, lines } sections, one per changed
-- file, keeping the @@ hunks and +/- lines but dropping the per-file chrome.
local function split_patch(patch)
  local sections = {}
  local cur = nil
  for _, line in ipairs(patch) do
    local newfile = line:match("^diff %-%-git a/.- b/(.+)$")
    if newfile then
      cur = { file = newfile, add = 0, del = 0, lines = {} }
      table.insert(sections, cur)
    elseif cur and not is_diff_noise(line) then
      if line:match("^%+") then
        cur.add = cur.add + 1
      elseif line:match("^%-") then
        cur.del = cur.del + 1
      end
      table.insert(cur.lines, line)
    end
  end
  return sections
end

--- Open the given commit (sha) from repo at `dir` as a foldfloat popup.
function M.open(dir, sha)
  if not sha or sha:match("^0+$") then
    vim.notify("No commit for this line (uncommitted?)", vim.log.levels.WARN)
    return
  end

  local hdr = git(dir, {
    "show", "-s", "--no-color",
    "--format=%s%n%h%n%an%n%ad", "--date=format:%Y-%m-%d %H:%M", sha,
  })
  if not hdr then
    vim.notify("git show failed for " .. sha, vim.log.levels.ERROR)
    return
  end
  local subject, short, author, date = hdr[1] or "", hdr[2] or "", hdr[3] or "", hdr[4] or ""
  local body = git(dir, { "show", "-s", "--no-color", "--format=%b", sha }) or {}
  local patch = git(dir, { "show", "--no-color", "--format=", "--patch", sha }) or {}

  local md = {
    "# " .. subject,
    "",
    ("`%s` · %s · %s"):format(short, author, date),
    "",
  }
  local has_body = false
  for _, l in ipairs(body) do
    if l ~= "" then
      has_body = true
      break
    end
  end
  if has_body then
    vim.list_extend(md, body)
    table.insert(md, "")
  end

  for _, sec in ipairs(split_patch(patch)) do
    table.insert(md, ("### %s  (+%d -%d)"):format(sec.file, sec.add, sec.del))
    table.insert(md, "")
    table.insert(md, "```diff")
    vim.list_extend(md, sec.lines)
    table.insert(md, "```")
    table.insert(md, "")
  end

  require("foldfloat").open({
    lines = md,
    title = ("commit %s  ·  <Tab> fold  ·  <C-l>/<C-h> all  ·  <C-n>/<C-p> file  ·  q close"):format(short),
    section_pattern = "^### ",
  })
end

--- Open the full commit history of `file` (every commit that touched it) as a
--- foldfloat popup: one collapsible entry per commit, expanding to that
--- commit's diff for the file. Follows renames.
function M.file_history(dir, file)
  local US = "\31" -- unit separator between metadata fields
  local SENT = "\30\30" -- record marker prefixing each commit's format line
  local out = git(dir, {
    "log", "--follow", "-p", "--no-color",
    "--format=" .. SENT .. "%h" .. US .. "%ad" .. US .. "%s",
    "--date=format:%Y-%m-%d", "--", file,
  })
  if not out then
    vim.notify("git log failed for " .. file, vim.log.levels.ERROR)
    return
  end

  local commits = {}
  local cur = nil
  for _, line in ipairs(out) do
    if line:sub(1, #SENT) == SENT then
      local h, date, subject = line:sub(#SENT + 1):match("^(.-)" .. US .. "(.-)" .. US .. "(.*)$")
      cur = { h = h, date = date, subject = subject, lines = {} }
      table.insert(commits, cur)
    elseif cur and line ~= "" and not line:match("^diff %-%-git") and not is_diff_noise(line) then
      table.insert(cur.lines, line)
    end
  end

  if #commits == 0 then
    vim.notify("No commit history for this file", vim.log.levels.WARN)
    return
  end

  local md = { ("# %s  (%d commits)"):format(vim.fn.fnamemodify(file, ":~:."), #commits), "" }
  for _, c in ipairs(commits) do
    table.insert(md, ("## %s · %s · %s"):format(c.h, c.date, c.subject))
    table.insert(md, "")
    table.insert(md, "```diff")
    vim.list_extend(md, c.lines)
    table.insert(md, "```")
    table.insert(md, "")
  end

  require("foldfloat").open({
    lines = md,
    title = ("history: %s  ·  <Tab> fold  ·  <C-l>/<C-h> all  ·  <C-n>/<C-p> commit  ·  q close"):format(
      vim.fn.fnamemodify(file, ":t")
    ),
    section_pattern = "^## ",
  })
end

return M
