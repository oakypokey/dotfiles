local registry = require 'lsp.registry'

registry.server('roslyn_ls', {
  filetypes = { 'cs' },
  root_markers = {
    "*.sln",
		"*.csproj",
		"global.json",
		"Directory.Build.props",
		"Directory.Build.targets",
  },
  settings = {
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'openFiles',
      dotnet_compiler_diagnostics_scope = 'openFiles',
    },
  },
})
