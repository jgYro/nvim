-- Ruff (Python linter + formatter) via its built-in language server.
-- Runs alongside pyright (types/completion); Ruff provides linting and, if
-- you use it, formatting. Binary: ~/.local/bin/ruff (`brew install ruff` or
-- `uv tool install ruff` if you relocate it).
return {
  cmd = { "/Users/jerichogregory/.local/bin/ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
}
