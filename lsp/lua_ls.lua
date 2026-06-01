-- lua-language-server. Binary: `brew install lua-language-server`.
-- This repo's .luarc.json already declares the `vim` global + runtime
-- library; the settings below are a fallback for editing Lua elsewhere.
return {
  cmd = { "/opt/homebrew/bin/lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
    },
  },
}
