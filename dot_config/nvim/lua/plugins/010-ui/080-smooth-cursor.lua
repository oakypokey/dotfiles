vim.pack.add {
  'https://github.com/sphamba/smear-cursor.nvim',
}

require('smear_cursor').setup {
  particles_enabled = true,
  particles_max_num = 20,
  stiffness = 0.5,
}
