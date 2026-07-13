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

  -- C-d/C-u: while a preview float is open (e.g. after P watch mode), scroll
  -- the preview half a page; otherwise scroll the tree with the usual centered
  -- half-page motion. preview.scroll() returns false when no preview is open.
  local function preview_half_page(direction)
    local ok, mgr = pcall(require, "nvim-tree-preview.manager")
    local half = 10
    if ok and mgr.instance and mgr.instance:is_valid() then
      local win = mgr.instance.preview_win
      if win and vim.api.nvim_win_is_valid(win) then
        half = math.max(1, math.floor(vim.api.nvim_win_get_height(win) / 2))
      end
    end
    return preview.scroll(direction * half)
  end
  vim.keymap.set("n", "<C-d>", function()
    if not preview_half_page(1) then
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-d>zz", true, false, true))
    end
  end, opts("Scroll preview / tree down"))
  vim.keymap.set("n", "<C-u>", function()
    if not preview_half_page(-1) then
      vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-u>zz", true, false, true))
    end
  end, opts("Scroll preview / tree up"))

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

  -- preview_open: is a preview float currently up? hscroll only does anything
  -- while one is, so C-h reuses it: scroll the preview left if open, otherwise
  -- collapse every expanded directory in the tree.
  local function preview_open()
    local ok, mgr = pcall(require, "nvim-tree-preview.manager")
    return ok and mgr.instance and mgr.instance:is_valid()
  end
  vim.keymap.set("n", "<C-h>", function()
    if preview_open() then
      hscroll(-8)
    else
      api.tree.collapse_all()
    end
  end, opts("Collapse all dirs / scroll preview left"))

  -- Open the node under the cursor in a split: C-- horizontal, C-| vertical.
  -- Vertical covers every way Ctrl+| can arrive: <C-bar> (kitty), <C-S-Bslash>
  -- (tmux csi-u), <C-Bslash> (iTerm2 legacy: Ctrl+| sends the same ^\ as Ctrl+\).
  vim.keymap.set("n", "<C-->", api.node.open.horizontal, opts("Open: horizontal split"))
  vim.keymap.set("n", "<C-bar>", api.node.open.vertical, opts("Open: vertical split"))
  vim.keymap.set("n", "<C-S-Bslash>", api.node.open.vertical, opts("Open: vertical split"))
  vim.keymap.set("n", "<C-Bslash>", api.node.open.vertical, opts("Open: vertical split"))

  -- h: walk outward. On an open directory, collapse it. Otherwise (a file, or a
  -- closed directory) jump up to the parent directory. So from a file deep in a
  -- tree, the first h lands on its parent dir and a second h closes that dir.
  vim.keymap.set("n", "h", function()
    local ok, node = pcall(api.tree.get_node_under_cursor)
    if ok and node then
      if node.type == "directory" and node.open then
        api.node.open.edit() -- toggles an open dir shut
      else
        api.node.navigate.parent()
      end
    end
  end, opts("Up to parent / close dir"))

  -- l: walk inward, the mirror of h. On a closed directory, expand it. On an
  -- already-open directory, step the cursor onto its first child. On a file, open
  -- it. So repeated l drills down into the tree without ever collapsing anything.
  vim.keymap.set("n", "l", function()
    local ok, node = pcall(api.tree.get_node_under_cursor)
    if ok and node then
      if node.type == "directory" then
        if node.open then
          vim.cmd("normal! j") -- already open: drop onto the first child
        else
          api.node.open.edit() -- closed: expand it
        end
      else
        api.node.open.edit() -- file: open it
      end
    end
  end, opts("Into dir / open file"))

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
