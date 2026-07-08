-- Nim (nimlangserver). Binary: `nimble install nimlangserver` (needs the nim
-- toolchain, which you have via `brew install nim`). Installs to
-- ~/.nimble/bin/nimlangserver; communicates over stdio by default.
return {
  cmd = { "/Users/jerichogregory/.nimble/bin/nimlangserver" },
  filetypes = { "nim" },
  root_markers = { "nim.cfg", "config.nims", ".git" },
}
