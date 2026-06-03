-- Treesitter injections for Go template files like *.html.tmpl
-- Depends on nvim-treesitter from plugins/090-treesitter/010-treesitter.lua

local gh = require 'util.github'

return {
  src = gh('ngynkvn/gotmpl.nvim'),
  ft = { 'gotmpl', 'gohtmltmpl', 'helm' },
  config = function() require('gotmpl').setup {} end,
}
