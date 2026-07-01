-- claudecode.lua
--
-- Brings Claude Code into neovim.
local repo = require 'tooling.repos'
local claudecode = require 'integrations.claudecode'

return repo.spec('claudecode', {
  lazy = true,
  dependencies = {
    repo.spec 'snacks',
  },
  cmd = function()
    return vim.g.ai_integration == 'claudecode' and claudecode.cmds or {}
  end,
  opts = claudecode.opts,
  config = claudecode.setup,
})
