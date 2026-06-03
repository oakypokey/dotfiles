-- lua/plugins/autoreload.lua
vim.pack.add { {
  src = 'https://github.com/ccntrq/autoreload.nvim',
} }

require('autoreload').setup {
  autoread = true,
  events = { 'BufEnter', 'FocusGained' },
  timer = {
    enabled = true,
    interval_ms = 3000,
    start_delay_ms = 0,
  },
  notify = {
    on_conflict = true,
    on_reload = true,
  },
}
