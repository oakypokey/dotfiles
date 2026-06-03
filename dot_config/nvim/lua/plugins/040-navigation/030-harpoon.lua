-- Depends on plenary.nvim and telescope.nvim from plugins/040-navigation/010-telescope.lua

vim.pack.add {
  {
    src = 'https://github.com/ThePrimeagen/harpoon',
    name = 'harpoon',
    version = 'harpoon2',
  },
}

local harpoon = require 'harpoon'

-- REQUIRED
harpoon:setup()
