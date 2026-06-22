local env = require 'lang.python.env'
local registry = require 'tooling.registry'

registry.lsp_server('basedpyright', {
  before_init = function()
    env.sync(true)
  end,
  settings = {
    basedpyright = {
      analysis = {
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
})

registry.lsp_server('ruff', {
  before_init = function()
    env.sync(true)
  end,
  on_attach = function(client) client.server_capabilities.hoverProvider = false end,
})

registry.linter('python', 'ruff')
registry.formatter('python', 'ruff_format', { mason = 'ruff' })
registry.format_on_save 'python'
registry.treesitter 'python'

registry.dap_tool 'debugpy'
registry.dap_dependency 'dap_python'
registry.dap_setup(function(context)
  local debugpy_python = context.mason_package_path('debugpy', 'venv/bin/python')
  require('dap-python').setup(debugpy_python or 'python3')
  require('dap-python').resolve_python = env.python
end)

registry.test_dependency 'neotest_python'
registry.test_adapter(function(context)
  local markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'tox.ini',
    'pytest.ini',
  }

  if not context.has_marker(markers) then return nil end
  return context.guarded_adapter(
    require 'neotest-python' {
      runner = 'pytest',
      dap = { justMyCode = false },
      args = { '-q' },
    },
    markers
  )
end)
