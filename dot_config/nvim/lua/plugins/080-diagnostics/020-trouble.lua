local gh = require 'util.github'

vim.pack.add({
  {
    src = gh 'folke/trouble.nvim',
    name = 'trouble.nvim',
  },
}, { load = false })
