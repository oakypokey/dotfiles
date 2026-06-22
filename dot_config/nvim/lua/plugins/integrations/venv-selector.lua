local repo = require 'tooling.repos'

local function sync_python_env() require('lang.python.env').sync(true) end

local function statusline_venv_parent() return require('lang.python.env').venv_parent() or '' end

return repo.spec('venv_selector', {
  ft = 'python',
  dependencies = {
    repo.spec 'snacks',
  },
  keys = {
    { '<leader>pv', '<cmd>VenvSelect<cr>', ft = 'python', desc = 'Select Python venv' },
  },
  opts = {
    options = {
      picker = 'snacks',
      on_venv_activate_callback = sync_python_env,
      on_venv_deactivate_callback = sync_python_env,
      statusline_func = {
        lualine = statusline_venv_parent,
      },
    },
    search = {},
  },
})
