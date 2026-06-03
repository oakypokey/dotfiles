local gh = require 'util.github'

vim.pack.add {
  gh 'sphamba/smear-cursor.nvim',
}

require('smear_cursor').setup {
  particles_enabled = true,
  particles_max_num = 20,
  stiffness = 0.5,
}
