local M = {}

local opencode_cmd = 'opencode --port'

---@type snacks.terminal.Opts
local snacks_terminal_opts = {
  win = {
    position = 'right',
    enter = false,
  },
}

function M.get_terminal()
  return require('snacks.terminal').get(opencode_cmd, {
    create = false,
  })
end

---@type opencode.Opts
vim.g.opencode_opts = {
  server = {
    start = function()
      local terminal = require 'snacks.terminal'
      local win = M.get_terminal()

      if win then
        win:show()
        return
      end

      terminal.open(opencode_cmd, snacks_terminal_opts)
    end,

    stop = function()
      local win = M.get_terminal()

      if win then win:close() end
    end,

    toggle = function() require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts) end,
  },
}

function M.setup()
  -- opencode config
  vim.o.autoread = true

  vim.keymap.set({ 'n', 'x' }, '<leader>aa', function() require('opencode').ask('@this ', { submit = true }) end, { desc = 'Ask opencode...' })
  vim.keymap.set({ 'n', 'x' }, '<leader>as', function() require('opencode').select() end, { desc = 'Select opencode...' })
  vim.keymap.set({ 'n', 'x' }, '<leader>ao', function() return require('opencode').operator '@this ' end, { desc = 'Add range to opencode', expr = true })
  vim.keymap.set('n', '<leader>aO', function() return require('opencode').operator('@this ' .. '_') end, { desc = 'Add line to opencode', expr = true })
  -- Avoid <leader> in terminal mode because Neovim watches for terminal keymaps and delays leader input.
  vim.keymap.set({ 'n', 't' }, '<C-.>', function() require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts) end, { desc = 'Toggle opencode' })

  -- opencode.nvim schedules Server.disconnect as an unbound method.
  local Server = require 'opencode.server'
  if not Server._chezmoi_disconnect_patched then
    local disconnect = Server.disconnect
    Server.disconnect = function(self)
      self = self or Server.connected
      if not self then return end
      return disconnect(self)
    end
    Server._chezmoi_disconnect_patched = true
  end
end

return M
