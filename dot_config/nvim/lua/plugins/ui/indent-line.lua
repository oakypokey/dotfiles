-- Add indentation guides even on blank lines

local repo = require 'tooling.repos'

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
return repo.spec('indent_line', {
  event = 'BufReadPost',
  main = 'ibl',
  opts = {},
})
