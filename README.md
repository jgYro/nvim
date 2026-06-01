# Neovim config

A personal Neovim configuration managed with the built-in `vim.pack` package
manager. Lua throughout, `<Space>` as both leader and local-leader.

## Requirements

- **Neovim 0.12+** (built with LuaJIT) — required for the built-in `vim.pack`
  package manager.
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** and
  **[fd](https://github.com/sharkdp/fd)** — used by Telescope for grep and file
  finding.
- **Node.js ≥ 22** — required by Copilot. The config auto-detects a suitable
  Node (prefers Homebrew, falls back to nvm); see `lua/plugin_config/copilot.lua`.

## Install

```sh
git clone https://github.com/jgYro/nvim.git ~/.config/nvim
nvim
```

On first launch `vim.pack` clones the plugins listed in
`lua/plugins/init.lua`. Versions are pinned in `nvim-pack-lock.json`.

## Layout

```
init.lua                  -- entry point; loads the modules below
.luarc.json               -- lua-language-server settings (knows the `vim` global)
nvim-pack-lock.json        -- vim.pack lock file (pinned plugin revisions)
lua/
  config/options.lua      -- editor options + leader keys
  keybinds/               -- general keymaps (clipboard, movement, terminal, ...)
  plugins/init.lua        -- vim.pack plugin list + per-plugin config loader
  plugin_config/          -- one file per plugin's setup
```

## Plugins

| Plugin | Purpose |
| --- | --- |
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) + [copilot-lsp](https://github.com/copilotlsp-nvim/copilot-lsp) | GitHub Copilot suggestions and Next Edit Suggestions |
| [markdown-plus.nvim](https://github.com/YousefHadder/markdown-plus.nvim) | Markdown editing (headings, lists, tables, links) |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Popup of available keybinds after a prefix |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) + [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Fuzzy finder |
| [harpoon](https://github.com/ThePrimeagen/harpoon) (v1) | Quick file marks and jumps |
| [flash.nvim](https://github.com/folke/flash.nvim) | Label-based motion (avy-style jump on `s`, plus `f`/`t` and search labels) |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (main) | Treesitter parsers + highlighting |
| [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) (main) | Treesitter-based textobjects (select / move) |
| [treesitter-modules.nvim](https://github.com/MeanderingProgrammer/treesitter-modules.nvim) | Highlight / indent / incremental-selection modules on the treesitter main branch |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | In-buffer markdown rendering (raw while editing, formatted in normal mode) |
| [blink.cmp](https://github.com/Saghen/blink.cmp) | Completion engine (LSP / path / snippets / buffer, Rust fuzzy matcher) |
| [oh-lucy.nvim](https://github.com/Yazeed1s/oh-lucy.nvim) | Colorscheme (`oh-lucy` variant) |

## Keybindings

Leader is `<Space>`.

### General

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>y` / `<leader>p` | n, v | Yank / paste via the system clipboard |
| `gh` / `gl` | n, v | Jump to first non-blank / end of line |
| `<C-d>` / `<C-u>` | n | Half-page scroll, kept centered |
| `n` / `N` | n | Next / previous search match, kept centered |
| `<leader>u` / `<leader>U` | n | Open a terminal (vertical / horizontal split) |
| `<C-u>` | t | Exit terminal mode |
| `Lq` / `Hq` | n | Next / previous quickfix entry |
| `<leader><leader>w` | n | Toggle word wrap |
| `<A-BS>` | i | Delete the word before the cursor |

### Telescope (`<leader>f`)

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Open buffers |
| `<leader>fh` | Help tags |
| `<leader>fo` | Recent files |
| `<leader>fr` | Resume last picker |

### Harpoon

| Key | Action |
| --- | --- |
| `<leader>a` | Add current file to the list |
| `<leader>e` | Toggle the harpoon menu |
| `<C-j>` / `<C-k>` / `<C-l>` / `<C-;>` | Jump to file 1 / 2 / 3 / 4 |

> `<C-;>` only works in GUI clients or terminals that support the kitty
> keyboard protocol; most plain terminals can't send it.

### Flash (motion)

| Key | Mode | Action |
| --- | --- | --- |
| `s` | n, x, o | Avy-style jump: type chars, press a label to jump |
| `f` / `F` / `t` / `T` | n, x, o | Char motions, enhanced with jump labels |
| `/` / `?` | n | Search, enhanced with jump labels |

### Treesitter textobjects

Select (visual / operator-pending, e.g. `vif`, `daf`):

| Key | Textobject |
| --- | --- |
| `af` / `if` | Function outer / inner |
| `ac` / `ic` | Class outer / inner |
| `aa` / `ia` | Parameter outer / inner |

Move (normal / visual / operator-pending):

| Key | Action |
| --- | --- |
| `]f` / `[f` | Next / previous function start |
| `]F` / `[F` | Next / previous function end |
| `]a` / `[a` | Next / previous parameter |

Incremental selection (matches the helix config): `<A-n>` to start / expand,
`<A-p>` to shrink.

### Markdown rendering

render-markdown displays markdown formatted in normal mode and reveals raw
text on the cursor line / in insert mode. Toggle with `:RenderMarkdown toggle`.
Heading and code-block icons require a Nerd Font.

### LSP / completion / diagnostics

LSP uses Neovim's **native** API: each server is a hand-written config in
[`lsp/`](lsp/) (`lsp/<name>.lua`), turned on with `vim.lsp.enable()` in
`lua/plugin_config/lsp.lua`. Completion is **blink.cmp** (its capabilities are
advertised to every server); diagnostics use `vim.diagnostic`.

Most LSP keymaps are Neovim defaults (no custom mapping needed):

| Key | Action |
| --- | --- |
| `grn` | Rename |
| `gra` | Code action |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `gO` | Document symbols |
| `K` | Hover |
| `<C-s>` (insert) | Signature help |
| `[d` / `]d` | Previous / next diagnostic |

Completion (blink, `default` preset): `<C-y>` accept, `<C-n>`/`<C-p>` select,
`<C-space>` open menu / docs, `<C-e>` hide. (`<C-k>` is left to Copilot.)

**Enabled servers** (binary must be installed — see the note atop each
`lsp/<name>.lua`): `lua_ls`, `rust_analyzer`, `dartls`, `pyright`, `gopls`,
`ts_ls`, `html`, `intelephense`, `tailwindcss`. To add one: drop a
`lsp/<name>.lua` returning `{ cmd, filetypes, root_markers }` and add its name
to the `vim.lsp.enable{}` list.

### Copilot

| Key | Mode | Action |
| --- | --- | --- |
| `<C-l>` | i | Accept suggestion |
| `<C-j>` / `<C-k>` | i | Next / previous suggestion |
| `<C-h>` | i | Dismiss suggestion |
| `<leader>l` | n | Accept Next Edit Suggestion and jump to it |

Markdown buffers also get the [markdown-plus
keymaps](https://github.com/YousefHadder/markdown-plus.nvim/wiki/5.Keymaps)
under the `<localleader>` (`<Space>`) prefix.
