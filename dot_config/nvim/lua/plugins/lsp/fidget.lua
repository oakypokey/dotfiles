local repo = require 'tooling.repos'

return repo.spec('lsp_status', {
  config = function()
    require('fidget').setup {
      notification = {
        override_vim_notify = true,
      },
    }
  end,
})
