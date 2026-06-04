-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- Depends on nvim-web-devicons when Nerd Font is enabled

local gh = require 'util.github'

return {
  src = gh('nvim-neo-tree/neo-tree.nvim'),
  version = vim.version.range('*'),
  dependencies = {
    { src = gh('nvim-lua/plenary.nvim') },
    { src = gh('MunifTanjim/nui.nvim') },
    { src = gh('nvim-tree/nvim-web-devicons'), enabled = vim.g.have_nerd_font },
  },
  init = function()
    vim.keymap.set('n', '\\', function() vim.cmd.Neotree 'reveal' end, { desc = 'NeoTree reveal', silent = true })
  end,
  config = function()
    require('neo-tree').setup {
      filesystem = {
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
}
