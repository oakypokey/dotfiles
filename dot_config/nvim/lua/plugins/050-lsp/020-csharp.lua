local registry = require 'lsp.registry'

registry.server('roslyn_ls', {
  filetypes = { 'razor', 'cs' },

  settings = {
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'openFiles',
      dotnet_compiler_diagnostics_scope = 'openFiles',
    },
  },
})
