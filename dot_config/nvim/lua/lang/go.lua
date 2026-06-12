local registry = require 'tooling.registry'

registry.treesitter 'go'

registry.dap_tool 'delve'
registry.dap_dependency 'dap_go'
registry.dap_setup(function()
  require('dap-go').setup {
    delve = {
      -- On Windows delve must be run attached or it crashes.
      detached = vim.fn.has 'win32' == 0,
    },
  }
end)

registry.test_dependency 'neotest_go'
registry.test_adapter(function(context)
  local markers = { 'go.mod' }
  if not context.has_marker(markers) then return nil end
  return context.guarded_adapter(
    require 'neotest-go' {
      experimental = { test_table = true },
    },
    markers
  )
end)
