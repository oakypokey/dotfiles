-- Add indentation guides even on blank lines

local gh = require 'util.github'

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
return {
  src = gh('lukas-reineke/indent-blankline.nvim'),
  event = 'BufReadPost',
  main = 'ibl',
  opts = {},
}
