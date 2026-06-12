local repo = require 'tooling.repos'

return repo.spec('smear_cursor', {
  event = 'VeryLazy',
  main = 'smear_cursor',
  opts = {
    particles_enabled = true,
    particles_max_num = 20,
    stiffness = 0.5,
  },
})
