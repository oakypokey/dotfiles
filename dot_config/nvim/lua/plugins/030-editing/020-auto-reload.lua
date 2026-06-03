-- lua/plugins/autoreload.lua
local gh = require 'util.github'

return {
  src = gh('ccntrq/autoreload.nvim'),
  event = 'VeryLazy',
  opts = {
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
  },
}
