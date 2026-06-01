-- rust-analyzer. Binary: `rustup component add rust-analyzer` (you have
-- rustup) or `brew install rust-analyzer`.
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
}
