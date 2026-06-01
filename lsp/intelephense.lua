-- PHP (intelephense). Binary: `npm i -g intelephense`.
return {
  cmd = { "/opt/homebrew/bin/intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = { "composer.json", ".git" },
}
