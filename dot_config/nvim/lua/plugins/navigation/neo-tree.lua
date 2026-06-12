-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- Depends on nvim-web-devicons when Nerd Font is enabled

local repo = require 'tooling.repos'

return repo.spec('neo_tree', {
  version = vim.version.range '*',
  dependencies = {
    repo.spec 'plenary',
    repo.spec 'nui',
    repo.spec('icons', { enabled = vim.g.have_nerd_font }),
  },
  init = function()
    vim.keymap.set('n', '\\', function() vim.cmd.Neotree 'reveal' end, { desc = 'NeoTree reveal', silent = true })
  end,
  config = function()
    require('neo-tree').setup {
      window = {
        mappings = {
          e = 'open',
          E = function() vim.cmd 'Neotree focus filesystem left' end,
          b = function() vim.cmd 'Neotree focus buffers left' end,
          g = function() vim.cmd 'Neotree focus git_status left' end,
          ['<space>'] = 'none',
        },
      },
      filesystem = {
        hijack_netrw_behavior = 'open_default',
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = {
            '.git',
            '.DS_Store',
          },
        },
      },
    }
  end,
})
