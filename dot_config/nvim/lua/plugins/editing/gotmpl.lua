-- Treesitter injections for Go template files like *.html.tmpl
-- Depends on nvim-treesitter.

local repo = require 'tooling.repos'

return repo.spec('gotmpl', {
  ft = { 'gotmpl', 'gohtmltmpl', 'helm' },
  config = function() require('gotmpl').setup {} end,
})
