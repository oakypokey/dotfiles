local repo = require 'tooling.repos'

return repo.spec('snacks', {
  config = function()
    require('snacks').setup {
      input = {},
      picker = {},
    }
  end,
})
