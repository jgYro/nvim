------------------
--
--
-- Movement Keybinds
--
--
------------------

-- Helix-style line motions: gh -> first non-blank char, gl -> end of line.
-- Mapped in normal and visual so they work as both motions and selections.
vim.keymap.set({ "n", "v" }, "gh", "_")
vim.keymap.set({ "n", "v" }, "gl", "$")

-- Keep the cursor centered while scrolling and searching, so context never
-- jumps to the screen edge. n/N also reopen any folds (zv) on the match.
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Default fold collapse. <C-l> stays owned by Harpoon globally; fold-oriented
-- views can override it buffer-locally for expand-all.
vim.keymap.set("n", "<C-h>", "zM", { desc = "Collapse all folds" })

-- Match tmux pane resizing: <C-w> + Shift-H/J/K/L starts a short repeat window,
-- so additional H/J/K/L presses resize without typing <C-w> again.
local resize_step = 5
local resize_repeat_timeout_ms = vim.o.timeoutlen > 0 and vim.o.timeoutlen or 1000
local resize_repeat_timer = nil
local resize_repeat_active = false
local resize_repeat_saved_maps = {}

local resize_directions = {
  H = { command = "vertical resize -" .. resize_step, desc = "Resize window left" },
  J = { command = "resize -" .. resize_step, desc = "Resize window up" },
  K = { command = "resize +" .. resize_step, desc = "Resize window down" },
  L = { command = "vertical resize +" .. resize_step, desc = "Resize window right" },
}

local function stop_resize_repeat()
  if resize_repeat_timer then
    resize_repeat_timer:stop()
    resize_repeat_timer:close()
    resize_repeat_timer = nil
  end

  if not resize_repeat_active then
    return
  end

  for key, saved_map in pairs(resize_repeat_saved_maps) do
    pcall(vim.keymap.del, "n", key)
    if saved_map then
      pcall(vim.fn.mapset, "n", false, saved_map)
    end
  end

  resize_repeat_saved_maps = {}
  resize_repeat_active = false
end

local function schedule_resize_repeat_stop()
  if resize_repeat_timer then
    resize_repeat_timer:stop()
    resize_repeat_timer:close()
  end

  resize_repeat_timer = vim.uv.new_timer()
  resize_repeat_timer:start(resize_repeat_timeout_ms, 0, vim.schedule_wrap(stop_resize_repeat))
end

local function resize_and_repeat(key)
  vim.cmd(resize_directions[key].command)
  vim.cmd("redraw")

  if not resize_repeat_active then
    for repeat_key, direction in pairs(resize_directions) do
      local existing_map = vim.fn.maparg(repeat_key, "n", false, true)
      resize_repeat_saved_maps[repeat_key] = existing_map.lhs and existing_map.lhs ~= "" and existing_map or nil

      local resize_key = repeat_key
      vim.keymap.set("n", resize_key, function()
        resize_and_repeat(resize_key)
      end, { nowait = true, desc = direction.desc .. " (repeat)" })
    end
    resize_repeat_active = true
  end

  schedule_resize_repeat_stop()
end

for key, direction in pairs(resize_directions) do
  local resize_key = key
  vim.keymap.set("n", "<C-w>" .. resize_key, function()
    resize_and_repeat(resize_key)
  end, { desc = direction.desc })
end
