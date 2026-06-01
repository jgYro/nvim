------------------
--
--
-- Configuration Imports
--
--
------------------

-- Static Neovim Options
require("config.options")
-- Insert Mode Keybinds
require("keybinds.insert_mode")
-- Movement Keybinds
require("keybinds.movement")
-- Clipboard Keybinds
require("keybinds.clipboard")
-- Quickfix Keybinds
require("keybinds.quickfix")
-- Terminal Keybinds
require("keybinds.terminal")
-- Word Wrap Keybinds
require("keybinds.word_wrap")
-- Plugins (vim.pack) + their configuration
require("plugins")
