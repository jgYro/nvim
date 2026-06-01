-- ESLint (vscode-eslint-language-server, from vscode-langservers-extracted).
-- Linting only -- formatting is left to prettier via conform.
return {
  cmd = { "/opt/homebrew/bin/vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "vue",
    "svelte",
  },
  root_markers = {
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    ".eslintrc.yaml",
    ".eslintrc.yml",
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    "eslint.config.ts",
    "package.json",
    ".git",
  },
  settings = {
    validate = "on",
    format = false, -- prettier (via conform) handles formatting
    run = "onType",
    workingDirectory = { mode = "location" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
}
