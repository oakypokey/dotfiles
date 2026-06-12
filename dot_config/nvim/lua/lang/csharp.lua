local registry = require 'tooling.registry'

registry.lsp_server('roslyn_ls', {
  filetypes = { 'cs' },
  mason = 'roslyn-language-server',
  root_markers = {
    '*.sln',
    '*.csproj',
    'global.json',
    'Directory.Build.props',
    'Directory.Build.targets',
  },
  settings = {
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'openFiles',
      dotnet_compiler_diagnostics_scope = 'openFiles',
    },
  },
})

registry.format_on_save 'cs'
registry.treesitter 'c_sharp'

registry.dap_tool 'netcoredbg'
registry.dap_dependency 'dap_dll_autopicker'
registry.dap_setup(function(context)
  local dap = require 'dap'
  local netcoredbg = context.mason_package_path('netcoredbg', 'netcoredbg')

  if not netcoredbg and vim.fn.executable 'netcoredbg' ~= 1 then return end

  local netcoredbg_adapter = {
    type = 'executable',
    command = netcoredbg or 'netcoredbg',
    args = { '--interpreter=vscode' },
  }
  dap.adapters.coreclr = netcoredbg_adapter
  dap.adapters.netcoredbg = netcoredbg_adapter

  local dotnet_configurations = {
    {
      type = 'coreclr',
      name = 'LAUNCH directly from nvim',
      request = 'launch',
      program = function() return require('dap-dll-autopicker').build_dll_path() end,
    },
  }

  for _, language in ipairs { 'cs', 'fsharp', 'vb' } do
    dap.configurations[language] = dotnet_configurations
  end
end)

registry.test_dependency 'neotest_vstest'
registry.test_adapter(function(context)
  local markers = { '*.csproj', '*.sln', 'global.json' }
  if not context.has_marker(markers) then return nil end
  return context.guarded_adapter(require 'neotest-vstest', markers)
end)
