local repo = require 'tooling.repos'

return repo.spec('overseer', {
  cmd = {
    'OverseerBuild',
    'OverseerClearCache',
    'OverseerClose',
    'OverseerDeleteBundle',
    'OverseerInfo',
    'OverseerLoadBundle',
    'OverseerOpen',
    'OverseerRun',
    'OverseerRunCmd',
    'OverseerSaveBundle',
    'OverseerTaskAction',
    'OverseerToggle',
  },
  keys = {
    {
      '<leader>or',
      function() require('overseer').run_task() end,
      desc = 'Overseer: Run Task',
    },
    {
      '<leader>oo',
      function() require('overseer').toggle() end,
      desc = 'Overseer: Toggle Tasks',
    },
    {
      '<leader>oa',
      function() require('overseer.commands').task_action() end,
      desc = 'Overseer: Task Action',
    },
  },
  config = function()
    require('overseer').setup {
      dap = false,
    }
  end,
})
