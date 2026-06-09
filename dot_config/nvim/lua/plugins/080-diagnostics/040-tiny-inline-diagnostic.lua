local gh = require 'util.github'

return {
  src = gh('rachartier/tiny-inline-diagnostic.nvim'),
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
}
