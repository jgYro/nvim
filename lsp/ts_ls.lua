-- TypeScript / JavaScript (ts_ls, formerly tsserver). Binary:
-- `npm i -g typescript typescript-language-server`.
return {
  cmd = { "/opt/homebrew/bin/typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
}
