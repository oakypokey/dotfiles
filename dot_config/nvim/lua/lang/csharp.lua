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
registry.dap_setup(function(context)
  local dap = require 'dap'
  local dap_utils = require 'dap.utils'
  local netcoredbg = context.mason_package_path('netcoredbg', 'netcoredbg')

  if not netcoredbg and vim.fn.executable 'netcoredbg' ~= 1 then return end

  local netcoredbg_adapter = {
    type = 'executable',
    command = netcoredbg or 'netcoredbg',
    args = { '--interpreter=vscode' },
    options = { detached = false },
  }
  dap.adapters.coreclr = netcoredbg_adapter
  dap.adapters.netcoredbg = netcoredbg_adapter

  local dotnet_configurations = {
    {
      type = 'netcoredbg',
      name = 'Launch .NET project',
      request = 'launch',
      program = function() return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file') end,
      cwd = '${workspaceFolder}',
      stopAtEntry = false,
      console = 'integratedTerminal',
      preLaunchTask = 'build',
    },
    {
      type = 'netcoredbg',
      name = 'Attach to .NET process',
      request = 'attach',
      processId = dap_utils.pick_process,
      cwd = '${workspaceFolder}',
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
