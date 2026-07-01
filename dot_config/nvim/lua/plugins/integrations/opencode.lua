-- opencode.lua
--
-- Brings opencode into neovim
local repo = require 'tooling.repos'
local opencode = require 'integrations.opencode'

return repo.spec('opencode', {
  lazy = true,
  version = vim.version.range '*',
  dependencies = {
    repo.spec 'snacks',
  },
  init = function() end,
  config = opencode.setup,
})
