------------------
--
--
-- oh-lucy (Yazeed1s/oh-lucy.nvim)
--
--
------------------

-- Colorscheme. There is no setup() function; options are plain globals that
-- must be set BEFORE the colorscheme command. Available knobs (all default
-- as noted; uncomment/flip to taste):
--   vim.g.oh_lucy_italic_comments        -- default true
--   vim.g.oh_lucy_italic_keywords        -- default true
--   vim.g.oh_lucy_italic_booleans        -- default false
--   vim.g.oh_lucy_italic_functions       -- default false
--   vim.g.oh_lucy_italic_variables       -- default true
--   vim.g.oh_lucy_transparent_background  -- default false
--
-- The sibling variant uses an oh_lucy_evening_ prefix and the colorscheme
-- name "oh-lucy-evening". Requires termguicolors (set in config/options.lua).

vim.cmd.colorscheme("oh-lucy")
