local gh = require 'util.github'

vim.pack.add({
  { src = gh 'mbbill/undotree', name = 'undotree' },
}, { load = false })
