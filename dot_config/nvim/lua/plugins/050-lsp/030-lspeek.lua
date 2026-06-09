local gh = require 'util.github'

return {
  src = gh('r4ppz/lspeek.nvim'),
  keys = {
    { 'grpd', function() require('lspeek').peek_definition() end, desc = '[G]oto [R] Peek [D]efinition' },
    { 'grpt', function() require('lspeek').peek_type_definition() end, desc = '[G]oto [R] Peek [T]ype Definition' },
  },
  opts = {
    window = {
      border = 'rounded',
    },
  },
}
