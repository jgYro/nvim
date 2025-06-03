-----------------------
---- Neovim Keymaps ----
------------------------
-- Emacs insert mode delete
vim.keymap.set("i", "<a-BS>", "<c-w>")

-- Execute (Source) file
vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")

-- Remap netrw mode in vim
vim.keymap.set("n", "<space>e", "<cmd>Explore<CR>")

-- Execute line
vim.keymap.set("n", "<space>x", ":.lua<CR>")

-- Execute selection
vim.keymap.set("v", "<space>x", ":lua<CR>")

-- Helix movement
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Copy to system clipboard
vim.keymap.set({ "v" }, "<leader>y", '"*y')
vim.keymap.set("n", "<leader>y", '"*yy', { noremap = true, silent = true })

-- Quickfix
vim.keymap.set("n", "Lq", ":cnext<CR>")
vim.keymap.set("n", "Hq", ":cprevious<CR>")

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
vim.keymap.set("n", "<space>ca", "<cmd>:lua vim.lsp.buf.code_action()<CR>")

-- Go to definition
vim.keymap.set("n", "gd", "<cmd>:lua vim.lsp.buf.definition()<CR>")

-- Open diagnostic fully
vim.keymap.set('n', '<space>d', '<cmd>:lua vim.diagnostic.open_float()<CR>')

-- Open diagnostic fully
vim.keymap.set('n', '<space><space>f', '<cmd>:lua vim.lsp.buf.format()<CR>')

-- Toggle inaly hints
vim.keymap.set('n', '<space><space>i', '<cmd>:lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<CR>')

-- Toggle word wrap
vim.keymap.set('n', '<space><space>w', function()
  if vim.wo.wrap then
    vim.wo.wrap = false
    vim.cmd('echo "Word wrapping OFF"')
  else
    vim.wo.wrap = true
    vim.cmd('echo "Word wrapping ON"')
  end
end)


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


------------------------
------ Neovim LSP ------
------ (No Rust) -------
------------------------
vim.diagnostic.config({
  virtual_lines = {
    current_line = true,
  },
})
--
-- lua
--
vim.lsp.config['luals'] = {
  -- Command and arguments to start the server.
  cmd = { 'lua-language-server' },
  -- Filetypes to automatically attach to.
  filetypes = { 'lua' },
  -- Sets the "root directory" to the parent directory of the file in the
  -- current buffer that contains either a ".luarc.json" or a
  -- ".luarc.jsonc" file. Files that share a root directory will reuse
  -- the connection to the same LSP server.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  -- Specific settings to send to the server. The schema for this is
  -- defined by the server. For example the schema for lua-language-server
  -- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      }
    }
  }
}
vim.lsp.enable('luals')
--
-- Rust
--

vim.lsp.config['rust'] = {
  -- Command and arguments to start the server.
  cmd = { 'rust-analyzer' },
  -- Filetypes to automatically attach to.
  filetypes = { 'rust' },
  -- Sets the "root directory" to the parent directory of the file in the
  -- current buffer that contains a Cargo.toml file or a .git directory.
  root_markers = { 'Cargo.toml', '.git' },
  -- Specific settings to send to the server. The schema for this is
  -- defined by the server.
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
    }
  }
}

vim.lsp.enable('rust')

--
-- Python
--
vim.lsp.config['python'] = {
  -- Command and arguments to start the server.
  cmd = { "basedpyright-langserver", "--stdio" },
  -- Filetypes to automatically attach to.
  filetypes = { 'python' },
  -- Sets the "root directory" to the parent directory of the file in the
  -- current buffer that contains a Cargo.toml file or a .git directory.
  root_markers = { 'venv', '.venv', '.git' },
  -- Specific settings to send to the server. The schema for this is
  -- defined by the server.
  settings = {
    python = {
      venvPath = vim.fn.expand("~") .. "/.virtualenvs",
    },
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        autoSearchPaths = true,
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "strict",
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          functionReturnTypes = true,
          genericTypes = false,
        },
      },
    },
  },
}

vim.lsp.enable('python')
--
-- web dev
--
vim.lsp.config['tsserver'] = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "tsx", "jsx" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  settings = {}

}

vim.lsp.enable('tsserver')

vim.lsp.config['tailwind'] = {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = { "css", "scss", "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  root_markers = { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts", ".git" },
  settings = {
  },
}

vim.lsp.enable('tailwind')
