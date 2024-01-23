-- Lazy / Plugin setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Needs to be here at the top before the plugins
vim.g.mapleader = " "

-- Needs to be here before it's installed?
vim.g.coq_settings = {
	auto_start = "shut-up",
	display = { icons = { mode = "none" } },
}

require("lazy").setup({
	-- LSP
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		dependencies = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{
				"williamboman/mason.nvim",
				dependencies = {
					"WhoIsSethDaniel/mason-tool-installer.nvim",
				},
				config = function()
					local mason = require("mason")

					local mason_tool_installer = require("mason-tool-installer")

					-- enable mason and configure icons
					mason.setup({
						ui = {
							icons = {
								package_installed = "✓",
								package_pending = "➜",
								package_uninstalled = "✗",
							},
						},
					})

					mason_tool_installer.setup({
						ensure_installed = {
							"prettier", -- prettier formatter
							"stylua", -- lua formatter
							"isort", -- python formatter
							"black", -- python formatter
							"pylint", -- python linter
							"eslint_d", -- js linter
							"shellcheck", -- bash linter
						},
					})
				end,
			},
			{ "williamboman/mason-lspconfig.nvim" },
			{ "jay-babu/mason-nvim-dap.nvim" },

			-- null-ls
			{ "jose-elias-alvarez/null-ls.nvim" },
			{ "jay-babu/mason-null-ls.nvim" },
		},
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")
			conform.setup({
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 500,
				},
				formatters_by_ft = {
					bash = { "shellcheck" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					svelte = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					graphql = { "prettier" },
					lua = { "stylua" },
					python = { "isort", "black" },
				},
			})
		end,
	},
	-- Linting
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				bash = { "shellcheck" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				python = { "pylint" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	-- Debugging
	{ "mfussenegger/nvim-dap" },
	{ "rcarriga/nvim-dap-ui" },
	{ "theHamsta/nvim-dap-virtual-text" },
	{ "nvim-telescope/telescope-dap.nvim" },
	{ "mfussenegger/nvim-dap-python" },

	--Harpoon
	{ "ThePrimeagen/harpoon" },

	-- Telescope
	{ "nvim-telescope/telescope.nvim" },

	-- Better commenting
	{ "numToStr/Comment.nvim", opts = {}, lazy = false },

	-- Better autopairs
	{ "windwp/nvim-autopairs", events = "InsertEnter", opts = {} },

	-- Treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	{ "nvim-treesitter/nvim-treesitter-context" },

	-- Color scheme
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },

	-- Needed by everything
	{ "nvim-lua/plenary.nvim" },

	-- Mini
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.move").setup()
		end,
	},

	{
		"amrbashir/nvim-docs-view",
		lazy = true,
		cmd = "DocsViewToggle",
		opts = {
			position = "bottom",
		},
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"andersevenrud/cmp-tmux",
			"kdheepak/cmp-latex-symbols",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
		},
	},
})

-- Color scheme
vim.cmd.colorscheme("catppuccin")

-- Set line numbers
vim.opt.nu = true

-- Set relative line numbers
vim.opt.relativenumber = true

-- I like how these look
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

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

--DAP
local dap = require("dap")

require("dap-python").setup("/usr/bin/python3")
require("nvim-dap-virtual-text").setup()
require("dapui").setup()

local dapui = require("dapui")

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

--Treesitter
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = { "python", "rust", "typescript", "dart", "bash", "go" },

	highlight = { enable = true },
	indent = { enable = true },
	rainbow = {
		enable = true,
		extended_mode = true,
	},
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<a-n>",
			node_incremental = "<a-n>",
			scope_incremental = "<c-s>",
			node_decremental = "<a-p>",
		},
	},
})

-- LSP
local lsp = require("lsp-zero").preset({})
local tele = require("telescope.builtin")

lsp.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "<leader>ws", function()
		vim.lsp.buf.workspace_symbol()
	end, opts)
	vim.keymap.set("n", "<leader>d", tele.diagnostics, opts)
	vim.keymap.set("n", "<leader>vd", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.goto_prev()
	end, opts)
	vim.keymap.set("n", "<leader>vca", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "<leader>vrr", function()
		vim.lsp.buf.references()
	end, opts)
	vim.keymap.set("n", "<leader>vrn", function()
		vim.lsp.buf.rename()
	end, opts)
	vim.keymap.set("i", "<C-h>", function()
		vim.lsp.buf.signature_help()
	end, opts)
end)
lsp.setup()
vim.diagnostic.config({
	virtual_text = true,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig").lua_ls.setup({
	capabilities = capabilities,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
require("lspconfig").bashls.setup({
	capabilities = capabilities,
})
require("lspconfig").pylsp.setup({
	capabilities = capabilities,
})
require("lspconfig").rust_analyzer.setup({
	capabilities = capabilities,
})
require("lspconfig").tsserver.setup({
	capabilities = capabilities,
	settings = {
		implicitProjectConfiguration = {
			checkJs = true,
		},
	},
})

-- Linting
require("lint").linters_by_ft = {
	markdown = { "shellcheck" },
}

-- CMP
local cmp = require("cmp")

vim.keymap.set("i", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>")
vim.keymap.set("s", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>")
vim.keymap.set("i", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>")
vim.keymap.set("s", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>")

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "latex_symbols" },
		{ name = "tmux" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>sp", builtin.spell_suggest, {})

-- Harpoon
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<leader>h", function()
	ui.nav_file(1)
end)
vim.keymap.set("n", "<leader>j", function()
	ui.nav_file(2)
end)
vim.keymap.set("n", "<leader>k", function()
	ui.nav_file(3)
end)
vim.keymap.set("n", "<leader>l", function()
	ui.nav_file(4)
end)

-- Key maps
-- Word wrapping
-- Define a custom function to toggle word wrapping
function ToggleWordWrap()
	if vim.wo.wrap then
		vim.wo.wrap = false
		vim.cmd('echo "Word wrapping OFF"')
	else
		vim.wo.wrap = true
		vim.cmd('echo "Word wrapping ON"')
	end
end

-- Toggle word wrapping
vim.keymap.set("n", "<leader>w", ":lua ToggleWordWrap()<CR>")

-- Toggle word wrapping
vim.keymap.set("n", "<leader>q", ":DocsViewToggle <CR>")

-- Center selections and movement
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Access & update config
vim.keymap.set("n", "<leader><leader>c", "<cmd>:e ~/.config/nvim/init.lua<CR>")
vim.keymap.set("n", "<leader><leader>r", "<cmd>:so %<CR>")

-- Splits
vim.keymap.set("n", "<C-w>|", "<cmd>:vsplit<CR>")
vim.keymap.set("n", "<C-w>-", "<cmd>:split<CR>")

-- Helix movement
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])

-- Send to tmux
vim.keymap.set("x", "<leader>t", ":!~/Yro/scripts/Py/repl.sh<CR>")

-- Test
function _G.process_visual_selection()
	-- Get the current buffer
	local bufnr = vim.api.nvim_get_current_buf()

	-- Get the positions of the start and end of the visual selection
	local start_pos = vim.api.nvim_buf_get_mark(bufnr, "<")
	local end_pos = vim.api.nvim_buf_get_mark(bufnr, ">")

	-- Adjust the end position to include the end of the line
	end_pos[2] = end_pos[2] + 1

	-- Get the text of the visual selection
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_pos[1] - 1, end_pos[1], false)

	-- process the selected text
	for _, line in ipairs(lines) do
		-- Escape selection
		local escaped_line = "'" .. line:gsub("'", "'\\''") .. "'"
		io.popen("tmux send-keys -t 1 " .. escaped_line .. " Enter >/dev/null 2>&1")
	end
end

vim.keymap.set("x", "<leader>p", ":lua process_visual_selection()<CR>")

-------
---
local ls = require("luasnip")
-- some shorthands...
local snip = ls.snippet
local node = ls.snippet_node
local text = ls.text_node
local insert = ls.insert_node
local func = ls.function_node
local choice = ls.choice_node
local dynamicn = ls.dynamic_node

local date = function()
	return { os.date("%Y-%m-%d") }
end

ls.add_snippets(nil, {
	all = {
		snip({
			trig = "date",
			namr = "Date",
			dscr = "Date in the form of YYYY-MM-DD",
		}, {
			func(date, {}),
		}),
		snip({
			trig = "meta",
			namr = "Metadata",
			dscr = "Yaml metadata format for markdown",
		}, {
			text({ "---", "title: " }),
			insert(1, "note_title"),
			text({ "", "author: " }),
			insert(2, "author"),
			text({ "", "date: " }),
			func(date, {}),
			text({ "", "categories: [" }),
			insert(3, ""),
			text({ "]", "lastmod: " }),
			func(date, {}),
			text({ "", "tags: [" }),
			insert(4),
			text({ "]", "comments: true", "---", "" }),
			insert(0),
		}),
	},
})
