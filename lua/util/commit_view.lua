------------------
--
--
-- commit_view: render a git commit as a clean, foldable markdown float
--
--
------------------

-- Used by gitsigns' <leader>hc. Renders the commit as markdown -- subject as a
-- heading, a metadata line, the body, then each changed file in its own
-- `### file (+adds -dels)` section with the diff in a ```diff block -- and
-- opens it in a centered float with the same foldable, tabbed-list UI as the
-- yank2think buffer: each file is a collapsed fold row, <Tab> expands it, and
-- the diff treesitter parser + render-markdown style the contents.

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
      -- Count real additions/removals (not the @@ hunk header).
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

-- foldexpr: keep the title/metadata/body at level 0 (always visible), and start
-- a level-1 fold at each `### file` section so every file is a collapsible row.
function M.foldexpr()
  local line = vim.fn.getline(vim.v.lnum)
  if line:match("^### ") then
    return ">1"
  end
  if line:match("^# ") then
    return "0"
  end
  return "=" -- inherit the previous line's level
end

-- Compact one-line summary for a collapsed file section.
function M.foldtext()
  local header = vim.fn.getline(vim.v.foldstart):gsub("^###%s*", "")
  return "  ▸ " .. header
end

--- Open the given commit (sha) from repo at `dir` as a foldable markdown float.
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
  -- Commit body, if any (skip when it's all blank lines).
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

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, md)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = (" commit %s  ·  <Tab> fold  ·  q close "):format(short),
    title_pos = "center",
  })

  vim.wo[win].foldmethod = "expr"
  vim.wo[win].foldexpr = 'v:lua.require("util.commit_view").foldexpr()'
  vim.wo[win].foldtext = 'v:lua.require("util.commit_view").foldtext()'
  vim.wo[win].fillchars = "fold: "
  vim.wo[win].foldenable = true
  vim.wo[win].foldlevel = 0 -- start collapsed: a compact, tabbed list of files
  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
  end
  map("<Tab>", "za", "Toggle file fold")
  -- A float has its own (empty) jumplist, so plain <C-o> would do nothing here.
  -- Map it -- and q / <Esc> -- to close the float, which returns you to the
  -- window and cursor you launched from. So <C-o> always takes you back.
  map("<C-o>", "<cmd>close<cr>", "Close commit view (back)")
  map("q", "<cmd>close<cr>", "Close commit view")
  map("<Esc>", "<cmd>close<cr>", "Close commit view")
end

return M
