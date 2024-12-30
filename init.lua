-----------------------
---- Neovim Keymaps ----
------------------------
-- Execute (Source) file
vim.keymap.set("n", "<space><space>x","<cmd>source %<CR>")

-- Remap netrw mode in vim
vim.keymap.set("n", "<space>e", "<cmd>Explore<CR>")

-- Execute line
vim.keymap.set("n", "<space>x",":.lua<CR>")

-- Execute selection
vim.keymap.set("v", "<space>x",":lua<CR>")

-- Helix movement
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["*y]])

-- Telescope
vim.keymap.set("n", "<space><space>t", ":Telescope<CR>")

-- Open new window with terminal
vim.keymap.set("n", "<space>t", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.startinsert()
end)

-- Get back to normal mode from terminal mode
vim.keymap.set('t', '<C-t>', "<C-\\><C-n>")

-- Copy selection to clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

-- Splits
vim.keymap.set("n", "<C-w>|", "<cmd>:vsplit<CR>")
vim.keymap.set("n", "<C-w>-", "<cmd>:split<CR>")

-- Helix movement
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Center selections and movement
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Move between quickfix entries
vim.keymap.set("n", "Lq", ":cnext<CR>zz")
vim.keymap.set("n", "Hq", ":cprevious<CR>zz")

-- Move between buffers
vim.keymap.set("n", "gn", ":tabnext<CR>")
vim.keymap.set("n", "gp", ":tabprevious<CR>")

-- LSP code action
vim.keymap.set("n", "<space>a", "<cmd>vim.lsp.buf.code_action<CR>")


-- Toggle cursor column and line
vim.keymap.set("n", "<space><space>X", function()
  if vim.o.cursorline then
		vim.o.cursorline = false
	else
		vim.o.cursorline = true
  end

  if vim.o.cursorcolumn then
		vim.o.cursorcolumn = false
	else
		vim.o.cursorcolumn = true
	end
end)

------------------------
---- Neovim Options ----
------------------------
-- Set line numbers
vim.opt.nu = true

-- Cursor change
vim.opt.guicursor = ""

-- Set relative line numbers
vim.opt.relativenumber = true

-- Formatting
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Autoindenting
vim.opt.smartindent = true

-- Disable word wrap
vim.opt.wrap = false

-- No swapfile, set up (plugin) undo tree
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Disable highlighting previous search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Better vim colors
vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")

-- Decrease updatetime
vim.opt.updatetime = 50

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- By default split below and to the right for new windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Tab
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

------------------------
---- Neovim Imports ----
------------------------
-- Import Package Manager
require("config.lazy")
