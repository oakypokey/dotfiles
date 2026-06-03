-- Depends on plenary.nvim and telescope.nvim from plugins/040-navigation/010-telescope.lua

local gh = require 'util.github'

vim.pack.add {
  {
    src = gh 'ThePrimeagen/harpoon',
    name = 'harpoon',
    version = 'harpoon2',
  },
}

local harpoon = require 'harpoon'

-- REQUIRED
harpoon:setup()
