vim.lsp.enable 'roslyn_ls'

vim.lsp.config('roslyn_ls', {
  filetypes = { 'razor', 'cs' },

  settings = {
    ['csharp|backround_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'openFiles',
      dotnet_compiler_diagnostics_scope = 'openFiles',
    },
  },
})
