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

-- oh-lucy makes float / popup-menu backgrounds only a hair darker than the
-- editor background (#14161d vs #1b1d26), so a popup anchored mid-line (e.g. an
-- LSP hover beginning right after `report.st`) blends into the code under it.
-- Darken those backgrounds noticeably so floats read as a distinct panel. We
-- merge over the existing highlight (preserving fg) and re-apply on every
-- :colorscheme so it survives reloads.
local FLOAT_BG = "#0d0f15" -- clearly darker than Normal's #1b1d26

local function darken_floats()
  for _, group in ipairs({ "NormalFloat", "FloatBorder", "Pmenu" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = FLOAT_BG
    vim.api.nvim_set_hl(0, group, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("oh_lucy_darker_floats", { clear = true }),
  pattern = "oh-lucy*",
  callback = darken_floats,
})
darken_floats() -- colorscheme is already set above, so apply now too
