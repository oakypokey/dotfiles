-- Treesitter injections for Go template files like *.html.tmpl
-- Depends on nvim-treesitter from plugins/090-treesitter/010-treesitter.lua

vim.pack.add { 'https://github.com/ngynkvn/gotmpl.nvim' }
require('gotmpl').setup {}
