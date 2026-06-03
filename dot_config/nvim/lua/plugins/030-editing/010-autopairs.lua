-- autopairs
-- https://github.com/windwp/nvim-autopairs

local gh = require 'util.github'

vim.pack.add { gh 'windwp/nvim-autopairs' }
require('nvim-autopairs').setup {}
