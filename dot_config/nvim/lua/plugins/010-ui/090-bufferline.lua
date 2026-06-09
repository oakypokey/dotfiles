local gh = require 'util.github'

return {
  src = gh('akinsho/bufferline.nvim'),
  version = vim.version.range('*'),
  dependencies = {
    { src = gh('nvim-tree/nvim-web-devicons'), enabled = vim.g.have_nerd_font },
  },
  config = function()
    vim.o.showtabline = 2

    require('bufferline').setup {
      options = {
        modified_icon = '',
        color_icons = true,
        diagnostics = 'nvim_lsp',
        always_show_bufferline = false,
        show_if_buffers_are_at_least = 2,
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = 'slope',
      },
    }

    local prefix = '<leader>b'
    vim.keymap.set('n', prefix .. 'S', '<Cmd>BufferLineSortByDirectory<CR>', { desc = 'Sort buffers by directory' })
    vim.keymap.set('n', prefix .. 's', '<Cmd>BufferLineSortByExtension<CR>', { desc = 'Sort buffers by extension' })
    vim.keymap.set('n', prefix .. '<', '<Cmd>BufferLineMovePrev<CR>', { desc = 'Move buffer left' })
    vim.keymap.set('n', prefix .. '>', '<Cmd>BufferLineMoveNext<CR>', { desc = 'Move buffer right' })
  end,
}
