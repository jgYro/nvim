------------------
--
--
-- gitsigns (lewis6991/gitsigns.nvim)
--
--
------------------

-- Shows git add/change/delete signs in the sign column (the "gutter") and
-- provides hunk navigation/staging. Defaults are sensible; we just turn it on.
require("gitsigns").setup({
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

    -- Jump between hunks.
    map("n", "]c", function() gs.nav_hunk("next") end, "Gitsigns: next hunk")
    map("n", "[c", function() gs.nav_hunk("prev") end, "Gitsigns: prev hunk")

    -- Stage / reset / preview the hunk under the cursor.
    map("n", "<leader>hs", gs.stage_hunk, "Gitsigns: stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "Gitsigns: reset hunk")
    map("n", "<leader>hp", gs.preview_hunk, "Gitsigns: preview hunk")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Gitsigns: blame line")
  end,
})
