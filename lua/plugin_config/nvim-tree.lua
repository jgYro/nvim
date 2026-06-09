------------------
--
--
-- nvim-tree (nvim-tree/nvim-tree.lua)
--
--
------------------

-- File explorer sidebar. nvim-tree recommends disabling netrw so the two
-- don't fight over directory buffers; do it before setup() runs.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Floating, scrollable file preview (b0o/nvim-tree-preview.lua). Defaults are
-- fine; this registers the in-preview keymaps (Tab toggles focus, etc.).
require("nvim-tree-preview").setup({
  -- Merge over the plugin defaults: while focused IN the preview float, open the
  -- file in a split. C-- horizontal (- looks horizontal), C-| vertical.
  keymaps = {
    ["<C-->"] = { open = "horizontal" },
    -- Vertical, every way Ctrl+| can arrive: <C-bar> (kitty), <C-S-Bslash>
    -- (tmux csi-u), <C-Bslash> (iTerm2 legacy Ctrl+| = ^\).
    ["<C-bar>"] = { open = "vertical" },
    ["<C-S-Bslash>"] = { open = "vertical" },
    ["<C-Bslash>"] = { open = "vertical" },
  },
})

-- Keymaps applied to the tree buffer. Because we pass a custom on_attach, we
-- must call default_on_attach first or we'd lose all of nvim-tree's defaults.
local function on_attach(bufnr)
  local api = require("nvim-tree.api")
  api.config.mappings.default_on_attach(bufnr)

  local preview = require("nvim-tree-preview")
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- P toggles "watch" mode: the preview auto-updates as the cursor moves over
  -- nodes. <Esc> turns it back off.
  vim.keymap.set("n", "P", preview.watch, opts("Preview (watch)"))
  vim.keymap.set("n", "<Esc>", preview.unwatch, opts("Close preview / unwatch"))

  -- Scroll the preview float without leaving the tree.
  vim.keymap.set("n", "<C-d>", function() preview.scroll(4) end, opts("Scroll preview down"))
  vim.keymap.set("n", "<C-u>", function() preview.scroll(-4) end, opts("Scroll preview up"))

  -- Horizontal scroll: the preview API only scrolls vertically, so we nudge the
  -- preview window's leftcol directly (works because the preview is nowrap).
  -- Reaches into the plugin's manager for the window handle; guarded so it no-ops
  -- if the preview isn't open or the internals change.
  local function hscroll(cols)
    local ok, mgr = pcall(require, "nvim-tree-preview.manager")
    if not (ok and mgr.instance and mgr.instance:is_valid()) then
      return
    end
    local win = mgr.instance.preview_win
    if not (win and vim.api.nvim_win_is_valid(win)) then
      return
    end
    vim.api.nvim_win_call(win, function()
      local view = vim.fn.winsaveview()
      view.leftcol = math.max(0, (view.leftcol or 0) + cols)
      vim.fn.winrestview(view)
    end)
  end
  vim.keymap.set("n", "<C-l>", function() hscroll(8) end, opts("Scroll preview right"))
  vim.keymap.set("n", "<C-h>", function() hscroll(-8) end, opts("Scroll preview left"))

  -- Open the node under the cursor in a split: C-- horizontal, C-| vertical.
  -- Vertical covers every way Ctrl+| can arrive: <C-bar> (kitty), <C-S-Bslash>
  -- (tmux csi-u), <C-Bslash> (iTerm2 legacy: Ctrl+| sends the same ^\ as Ctrl+\).
  vim.keymap.set("n", "<C-->", api.node.open.horizontal, opts("Open: horizontal split"))
  vim.keymap.set("n", "<C-bar>", api.node.open.vertical, opts("Open: vertical split"))
  vim.keymap.set("n", "<C-S-Bslash>", api.node.open.vertical, opts("Open: vertical split"))
  vim.keymap.set("n", "<C-Bslash>", api.node.open.vertical, opts("Open: vertical split"))

  -- Tab: preview a file (and toggle focus into it); on a directory, expand it.
  vim.keymap.set("n", "<Tab>", function()
    local ok, node = pcall(api.tree.get_node_under_cursor)
    if ok and node then
      if node.type == "directory" then
        api.node.open.edit()
      else
        preview.node(node, { toggle_focus = true })
      end
    end
  end, opts("Preview"))
end

require("nvim-tree").setup({
  on_attach = on_attach,
  -- Git integration is on by default; turn its highlighting into filename
  -- colors. "name" tints the file/folder name (not just the status icon) by
  -- git status (modified, staged, untracked, ...) using the NvimTreeGit*HL
  -- groups. Use "all" to also colour the icon, "icon" for icon-only.
  git = { enable = true },
  renderer = {
    highlight_git = "name",
    -- Stop singling out README/Makefile/Cargo.toml in red so git status is
    -- the only thing colouring filenames.
    special_files = {},
  },
})

-- Compatibility shim for nvim-tree-preview.lua: it reads the now-removed
-- `require("nvim-tree").config.view.side`. On the nvim-tree rewrite the merged
-- config moved to `require("nvim-tree.config").g`, so point the old field at it.
-- (Must run after setup(), which is what populates config.g.)
local nt = require("nvim-tree")
if nt.config == nil then
  nt.config = require("nvim-tree.config").g
end

-- Toggle the tree.
vim.keymap.set("n", "<leader>ft", "<cmd>NvimTreeToggle<cr>", { desc = "File tree (nvim-tree)" })
