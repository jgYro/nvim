-- Tailwind CSS (tailwindcss-language-server). Binary:
-- `npm i -g @tailwindcss/language-server`.
return {
  cmd = { "/opt/homebrew/bin/tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "php",
  },
  root_markers = {
    "tailwind.config.js",
    "tailwind.config.ts",
    "tailwind.config.cjs",
    "postcss.config.js",
    "package.json",
    ".git",
  },
}
