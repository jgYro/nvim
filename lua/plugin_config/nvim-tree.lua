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
require("nvim-tree-preview").setup({})

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
