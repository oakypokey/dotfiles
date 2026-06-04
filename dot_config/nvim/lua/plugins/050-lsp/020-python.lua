local gh = require 'util.github'
local registry = require 'lsp.registry'

registry.server('basedpyright', {
  settings = {
    basedpyright = {
      analysis = {
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
})

registry.server('ruff', {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
})

return {
  src = gh('tnfru/nvim-venv-detector'),
  event = 'VimEnter',
  config = function()
    require('venv_detector').setup {
      auto_activate_venv = true,
      auto_restart_lsp = true,

      lsp_client_names = {
        'pyright',
        'pylsp',
        'ruff',
        'ruff_lsp',
        'basedpyright',
        'python',
      },

      notify = true,
    }
  end,
}
