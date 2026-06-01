-- Go (gopls). Binary: `go install golang.org/x/tools/gopls@latest` or
-- `brew install gopls`.
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
}
