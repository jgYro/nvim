-- PHP (intelephense). Binary: `npm i -g intelephense`.
return {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = { "composer.json", ".git" },
}
