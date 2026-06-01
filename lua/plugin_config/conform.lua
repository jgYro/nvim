------------------
--
--
-- conform.nvim (stevearc/conform.nvim) -- formatting
--
--
------------------

-- Format-on-save via external formatters, with a fallback to LSP formatting
-- for filetypes that have no formatter configured here (go / rust / dart /
-- php format through their language servers). stylua and prettier are on
-- Neovim's PATH (Homebrew); ruff lives in ~/.local/bin, so it is pinned.

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
  },
  formatters = {
    ruff_format = { command = "/Users/jerichogregory/.local/bin/ruff" },
  },
  format_on_save = {
    timeout_ms = 1500,
    lsp_format = "fallback",
  },
})
