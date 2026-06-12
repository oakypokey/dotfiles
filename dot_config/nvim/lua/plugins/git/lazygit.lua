local repo = require 'tooling.repos'

return repo.spec('lazygit', {
  event = 'VeryLazy',
  dependencies = {
    repo.spec 'plenary',
  },
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  keys = {
    { '<leader>gg', '<cmd>LazyGit<cr>', desc = '[G]it Lazy[G]it' },
  },
})
