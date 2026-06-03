-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- Depends on plenary.nvim from plugins/040-navigation/010-telescope.lua
-- Depends on nvim-web-devicons from plugins/010-ui/020-icons.lua when Nerd Font is enabled

local gh = require 'util.github'

vim.pack.add {
  { src = gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  gh 'MunifTanjim/nui.nvim',
}

require('neo-tree').setup {
  filesystem = {
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
        '.DS_Store'
      }
    }
  },
}
