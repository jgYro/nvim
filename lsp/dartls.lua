-- Dart / Flutter language server. Ships with the Dart/Flutter SDK
-- (`dart language-server`).
return {
  cmd = { "/Users/jerichogregory/Dev/flutter/bin/dart", "language-server", "--protocol=lsp" },
  filetypes = { "dart" },
  root_markers = { "pubspec.yaml", ".git" },
}
