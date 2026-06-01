-- golangci-lint via golangci-lint-langserver. Surfaces golangci-lint findings
-- as diagnostics (alongside gopls). Binaries (both in ~/go/bin):
--   go install github.com/nametake/golangci-lint-langserver@latest
--   go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
-- The `--out-format json` flag matches golangci-lint v1.x (you have v1.63).
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
      "/Users/jerichogregory/go/bin/golangci-lint",
      "run",
      "--out-format",
      "json",
    },
  },
}
