local gh = require 'util.github'

return {
  src = gh('folke/snacks.nvim'),
  config = function()
    require('snacks').setup {
      input = {},
      picker = {},
    }
  end,
}
