------------------
--
--
-- Treesitter (main branch) + textobjects + modules
--
--
------------------

-- nvim-treesitter is used on its `main` branch (the rewrite), which only
-- ships the parser/install machinery -- highlighting is started per buffer by
-- Neovim itself. The classic module experience (highlight / indent /
-- incremental selection) is layered back on via treesitter-modules.nvim, and
-- textobjects come from the nvim-treesitter-textobjects `main` branch with
-- explicit keymaps (the new API has no built-in keymap table).

-- The main branch requires `:TSUpdate` whenever the plugin itself updates, to
-- keep compiled parsers in sync with the queries. vim.pack has no build hook,
-- so run it from the PackChanged event for this plugin only.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("treesitter_update", { clear = true }),
  callback = function(ev)
    local d = ev.data or {}
    if d.spec and d.spec.name == "nvim-treesitter" and (d.kind == "install" or d.kind == "update") then
      vim.schedule(function()
        pcall(function()
          vim.cmd("TSUpdate")
        end)
      end)
    end
  end,
})

-- Highlight / indent / incremental selection, driven by treesitter-modules.
require("treesitter-modules").setup({
  ensure_installed = {
    "lua", "vim", "vimdoc", "query",
    "markdown", "markdown_inline",
    "bash", "json", "yaml",
  },
  auto_install = true, -- install missing parsers when entering a buffer
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      -- Deliberately off the gr* prefix, which holds Neovim's built-in LSP
      -- maps (grn rename, gra code action, grr references, ...).
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = "<C-s>",
      node_decremental = "<M-space>",
    },
  },
})

-- Textobjects (main branch): keymaps are defined by hand against the new API.
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true }, -- record jumps so <C-o>/<C-i> work
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

-- Select a textobject in visual / operator-pending mode (e.g. `vif`, `daf`).
local select_maps = {
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ac"] = "@class.outer",
  ["ic"] = "@class.inner",
  ["aa"] = "@parameter.outer",
  ["ia"] = "@parameter.inner",
}
for lhs, obj in pairs(select_maps) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    select.select_textobject(obj, "textobjects")
  end, { desc = "TS select " .. obj })
end

-- Jump between textobjects. `;`/`,` are left to flash, so these are not made
-- repeatable via repeatable_move.
vim.keymap.set({ "n", "x", "o" }, "]f", function()
  move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function start" })
vim.keymap.set({ "n", "x", "o" }, "[f", function()
  move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Prev function start" })
vim.keymap.set({ "n", "x", "o" }, "]F", function()
  move.goto_next_end("@function.outer", "textobjects")
end, { desc = "Next function end" })
vim.keymap.set({ "n", "x", "o" }, "[F", function()
  move.goto_previous_end("@function.outer", "textobjects")
end, { desc = "Prev function end" })
vim.keymap.set({ "n", "x", "o" }, "]a", function()
  move.goto_next_start("@parameter.inner", "textobjects")
end, { desc = "Next parameter" })
vim.keymap.set({ "n", "x", "o" }, "[a", function()
  move.goto_previous_start("@parameter.inner", "textobjects")
end, { desc = "Prev parameter" })
