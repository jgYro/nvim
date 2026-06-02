-- golangci-lint via golangci-lint-langserver. Surfaces golangci-lint findings
-- as diagnostics (alongside gopls).
--   langserver:   go install github.com/nametake/golangci-lint-langserver@latest
--   golangci-lint: brew install golangci-lint  (must be built with a Go >= the
--                  project's go.mod target, else it refuses to run)
-- golangci-lint v2 uses `--output.json.path stdout` (v1's `--out-format json`
-- was removed). `--show-stats=false` is required: v2 otherwise appends a stats
-- summary after the JSON, which breaks the langserver's JSON parser
-- ("invalid character '1' after top-level value").
return {
  cmd = { "/Users/jerichogregory/go/bin/golangci-lint-langserver" },
  filetypes = { "go", "gomod" },
  root_markers = {
    ".golangci.yml",
    ".golangci.yaml",
    ".golangci.toml",
    ".golangci.json",
    "go.mod",
    ".git",
  },
  init_options = {
    command = {
      "/opt/homebrew/bin/golangci-lint",
      "run",
      "--output.json.path",
      "stdout",
      "--show-stats=false",
    },
  },
}
