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
