local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================

-- [[ LSP Configuration ]]
-- Language files register servers and tools through tooling.registry before zpack setup.

return repo.spec('lsp', {
  dependencies = {
    repo.spec 'mason',
    repo.spec('lsp_status', { opts = {} }),
  },
  config = function()
    for name, server in pairs(registry.lsp.servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
})
