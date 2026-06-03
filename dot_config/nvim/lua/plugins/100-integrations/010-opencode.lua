-- opencode.lua
--
-- Brings opencode into neovim
local gh = require 'util.github'

vim.pack.add {
  {
    src = gh 'nickjvandyke/opencode.nvim',
    version = vim.version.range '*',
  },
  {
    src = gh 'folke/snacks.nvim',
  },
}

-- opencode config
vim.g.opencode_opts = {}

vim.o.autoread = true

-- snacks integration
require('snacks').setup {
  input = {},
  picker = {
    actions = {
      opencode_send = function(...) return require('opencode').snacks_picker_send(...) end,
    },
    win = {
      input = {
        keys = {
          ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
        },
      },
    },
  },
}
