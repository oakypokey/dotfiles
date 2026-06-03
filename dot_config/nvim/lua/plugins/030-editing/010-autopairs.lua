-- autopairs
-- https://github.com/windwp/nvim-autopairs

local gh = require 'util.github'

return {
  src = gh('windwp/nvim-autopairs'),
  event = 'InsertEnter',
  opts = {},
}
