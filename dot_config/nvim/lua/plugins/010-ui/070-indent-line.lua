-- Add indentation guides even on blank lines

local gh = require 'util.github'

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { gh 'lukas-reineke/indent-blankline.nvim' }
require('ibl').setup {}
