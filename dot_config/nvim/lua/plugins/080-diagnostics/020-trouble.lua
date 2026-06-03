local gh = require 'util.github'

local function trouble(mode, opts)
  return function() require('trouble').toggle(mode, opts) end
end

return {
  src = gh('folke/trouble.nvim'),
  name = 'trouble.nvim',
  cmd = 'Trouble',
  keys = {
    { '<leader>xx', trouble 'diagnostics', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', trouble('diagnostics', { filter = { buf = 0 } }), desc = 'Buffer Diagnostics (Trouble)' },
    { '<leader>cs', trouble('symbols', { focus = false }), desc = 'Symbols (Trouble)' },
    { '<leader>cL', trouble('lsp', { focus = false, win = { position = 'right' } }), desc = 'LSP Definitions / references / ... (Trouble)' },
    { '<leader>xL', trouble 'loclist', desc = 'Location List (Trouble)' },
    { '<leader>xQ', trouble 'qflist', desc = 'Quickfix List (Trouble)' },
  },
  opts = {},
}
