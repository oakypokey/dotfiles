local registry = require 'lsp.registry'

registry.server('ts_ls', {
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, {
      'tsconfig.json',
      'jsconfig.json',
      'deno.json',
      'deno.jsonc',
      'deno.lock',
      'package.json',
      'package-lock.json',
      'yarn.lock',
      'pnpm-lock.yaml',
      'bun.lock',
      'bun.lockb',
      '.git',
    }) or vim.fn.getcwd())
  end,
})
