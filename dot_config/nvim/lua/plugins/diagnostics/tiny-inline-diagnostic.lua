local repo = require 'tooling.repos'

return repo.spec('tiny_inline_diagnostic', {
  event = 'VeryLazy',
  priority = 1000,
  config = function()
    require('tiny-inline-diagnostic').setup {
      show_source = {
        enabled = true,
        if_many = true,
      },
      show_code = true,
      multilines = { enabled = true },
      override_open_float = true,
    }
  end,
})
