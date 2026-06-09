local gh = require 'util.github'

-- Useful plugin to show you pending keybinds.
return {
  src = gh('folke/which-key.nvim'),
  event = 'VeryLazy',
  config = function()
    require('which-key').setup {
      -- Delay between pressing a key and opening which-key (milliseconds)
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      -- Document existing key chains
      spec = {
        { '<leader>a', group = '[A]I / opencode', mode = { 'n', 'v' } },
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    }
  end,
}
