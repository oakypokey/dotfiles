-- Treesitter injections for Go template files like *.html.tmpl
-- Depends on nvim-treesitter from plugins/090-treesitter/010-treesitter.lua

local gh = require 'util.github'

vim.pack.add { gh 'ngynkvn/gotmpl.nvim' }
require('gotmpl').setup {}
