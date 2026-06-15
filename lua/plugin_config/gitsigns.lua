------------------
--
--
-- gitsigns (lewis6991/gitsigns.nvim)
--
--
------------------

-- Shows git add/change/delete signs in the sign column (the "gutter") and
-- provides hunk navigation/staging. Defaults are sensible; we just turn it on.
local focus_float = require("util.focus_float")

require("gitsigns").setup({
  -- Attach to untracked (brand-new, not-yet-staged) files too, so they show
  -- the `untracked` sign in the gutter. Off by default in gitsigns, which is
  -- why new files otherwise show no signs until staged.
  attach_to_untracked = true,
  -- Characters drawn in the gutter per hunk type.
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Jump between hunks (git changes). Bound both the Vim-idiomatic ]c/[c
    -- and the Lc/Hc forms matching our Lq/Hq quickfix idiom (L = forward,
    -- H = back). Buffer-local, since hunks only exist in tracked files.
    map("n", "]c", function() gs.nav_hunk("next") end, "Gitsigns: next hunk")
    map("n", "[c", function() gs.nav_hunk("prev") end, "Gitsigns: prev hunk")
    map("n", "Lc", function() gs.nav_hunk("next") end, "Next git change (hunk)")
    map("n", "Hc", function() gs.nav_hunk("prev") end, "Prev git change (hunk)")

    -- Stage / reset / preview the hunk under the cursor.
    map("n", "<leader>hs", gs.stage_hunk, "Gitsigns: stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "Gitsigns: reset hunk")
    map("n", "<leader>hp", gs.preview_hunk, "Gitsigns: preview hunk")

    -- <leader>hb: blame the current line, then jump into the popup and dim the
    -- code behind it -- the same focus + dim behavior as the LSP hover (K),
    -- via the shared util.focus_float helper. gitsigns doesn't hand back the
    -- float's window id, so we snapshot the floats that are open before the
    -- call and poll for the new one.
    map("n", "<leader>hb", function()
      local src = vim.api.nvim_get_current_buf()
      local before = {}
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(w).relative ~= "" then
          before[w] = true
        end
      end
      gs.blame_line({ full = true })
      focus_float.focus_when_ready(src, function()
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(w).relative ~= "" and not before[w] then
            return w
          end
        end
        return nil
      end, 50)
    end, "Gitsigns: blame line (focus + dim)")

    -- <leader>hc: open the FULL commit that last touched the current line --
    -- every hunk that commit changed, not just the one under the cursor. (The
    -- blame popup only ever shows the single nearest hunk; its "Hunk N of M"
    -- is static, with no way to step through the rest.) We resolve the line's
    -- commit via git blame, then render it as a clean markdown buffer.
    map("n", "<leader>hc", function()
      local file = vim.api.nvim_buf_get_name(0)
      local dir = vim.fs.dirname(file)
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      local first = vim.fn.systemlist({
        "git", "-C", dir,
        "blame", "-L", lnum .. "," .. lnum, "--porcelain", "--", file,
      })[1]
      local sha = first and first:match("^(%x+)")
      require("util.commit_view").open(dir, sha)
    end, "Gitsigns: show full commit for line")
  end,
})
