local repo = require 'tooling.repos'

return repo.spec('snacks', {
  priority = 0,
  config = function()
    --@type snacks.Config
    require('snacks').setup {
      dashboard = { sections = {
        { section = 'header' },
        { section = 'keys' },
      } },
      input = {},
      picker = {},
      explorer = {},
      scope = {},
    }
  end,
})
