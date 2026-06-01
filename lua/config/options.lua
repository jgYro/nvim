------------------
--
--
-- Editor Options & Leaders
--
--
------------------

-- Prefer Homebrew's toolchain for processes Neovim spawns. Node-based LSP
-- servers use `#!/usr/bin/env node`, which would otherwise resolve to the
-- nvm-active node (v20); prepending /opt/homebrew/bin keeps `node` at the
-- latest (v25). Absolute-pinned servers are unaffected; :terminal re-sources
-- your shell profile, so interactive nvm usage is untouched.
vim.env.PATH = "/opt/homebrew/bin:" .. (vim.env.PATH or "")

-- Leaders. Must be set before plugins/keymaps load, which is why they
-- live here (options is the first module required in init.lua). Both are
-- set to <Space> following the common kickstart.nvim convention:
-- <leader> for global maps, <localleader> for filetype-local maps
-- (e.g. markdown-plus).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Use 24-bit (true) colors in the terminal. Required for modern
-- colorschemes like oh-lucy to render correctly.
vim.opt.termguicolors = true

-- Line numbers: absolute on the cursor line, relative elsewhere (great
-- for counting motions like 5j).
vim.opt.nu = true
vim.opt.relativenumber = true

-- Indentation: 2-space soft tabs everywhere.
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Copy the current line's indent when starting a new line.
vim.opt.smartindent = true

-- Long lines run off-screen instead of wrapping.
vim.opt.wrap = false

-- No swap/backup files. Persist undo history to disk instead, so undo
-- survives across sessions (paired with an undo-tree plugin).
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Don't keep matches highlighted after a search; do highlight as you type.
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Case-insensitive search unless the pattern contains a capital (or \C).
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep 8 lines of context above/below the cursor, and treat "@-@" as part
-- of a filename (so gf works on more paths).
vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")

-- Faster CursorHold / swap-write events (snappier LSP, plugins).
vim.opt.updatetime = 50

-- Show the completion menu even for one match, and never auto-select.
vim.o.completeopt = "menuone,noselect"

-- New splits open below and to the right.
vim.opt.splitright = true
vim.opt.splitbelow = true
