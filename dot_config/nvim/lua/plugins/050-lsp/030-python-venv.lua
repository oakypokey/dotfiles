vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.pack.add {
      'https://github.com/tnfru/nvim-venv-detector',
    }

    require('venv_detector').setup {
      auto_activate_venv = true,
      auto_restart_lsp = true,

      lsp_client_names = {
        'pyright',
        'pylsp',
        'ruff',
        'ruff_lsp',
        'basedpyright',
        'python',
      },

      notify = true,
    }
  end,
})
