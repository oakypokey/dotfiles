-- autopairs
-- https://github.com/windwp/nvim-autopairs

local repo = require 'tooling.repos'

return repo.spec('autopairs', {
  event = 'InsertEnter',
  opts = {},
})
