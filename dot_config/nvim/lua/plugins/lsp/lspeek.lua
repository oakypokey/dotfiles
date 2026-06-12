local repo = require 'tooling.repos'

return repo.spec('lsp_peek', {
  keys = {
    { 'grpd', function() require('lspeek').peek_definition() end, desc = '[G]oto [R] Peek [D]efinition' },
    { 'grpt', function() require('lspeek').peek_type_definition() end, desc = '[G]oto [R] Peek [T]ype Definition' },
  },
  opts = {
    window = {
      border = 'rounded',
    },
  },
})
