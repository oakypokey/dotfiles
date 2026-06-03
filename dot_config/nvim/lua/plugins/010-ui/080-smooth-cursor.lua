local gh = require 'util.github'

return {
  src = gh('sphamba/smear-cursor.nvim'),
  event = 'VeryLazy',
  main = 'smear_cursor',
  opts = {
    particles_enabled = true,
    particles_max_num = 20,
    stiffness = 0.5,
  },
}
