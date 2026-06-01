-- rust-analyzer. Binary: `rustup component add rust-analyzer` (you have
-- rustup) or `brew install rust-analyzer`.
return {
  cmd = { "/Users/jerichogregory/.rustup/toolchains/nightly-aarch64-apple-darwin/bin/rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
}
