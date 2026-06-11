-- opencode.lua
--
-- Brings opencode into neovim
local gh = require 'util.github'

local function terminal_width()
  return math.floor(vim.o.columns * 0.35)
end

local opencode_terminal = {
  buf = nil,
  win = nil,
}

local function open_opencode_terminal()
  if opencode_terminal.win and vim.api.nvim_win_is_valid(opencode_terminal.win) then
    return
  end

  if opencode_terminal.buf and vim.api.nvim_buf_is_valid(opencode_terminal.buf) then
    vim.cmd(('botright vertical sbuffer %d'):format(opencode_terminal.buf))
    vim.cmd(('vertical resize %d'):format(terminal_width()))
    opencode_terminal.win = vim.api.nvim_get_current_win()
    return
  end

  vim.cmd('botright vertical terminal opencode --port')
  vim.cmd(('vertical resize %d'):format(terminal_width()))
  opencode_terminal.win = vim.api.nvim_get_current_win()
  opencode_terminal.buf = vim.api.nvim_get_current_buf()
  require('opencode.terminal').setup(vim.api.nvim_get_current_win())
end

local function toggle_opencode_terminal()
  if opencode_terminal.win and vim.api.nvim_win_is_valid(opencode_terminal.win) then
    vim.api.nvim_win_hide(opencode_terminal.win)
    opencode_terminal.win = nil
    return
  end

  open_opencode_terminal()
end

return {
  src = gh('nickjvandyke/opencode.nvim'),
  version = vim.version.range('*'),
  lazy = false,
  init = function()
    -- opencode config
    vim.g.opencode_opts = {}
    vim.o.autoread = true

    vim.keymap.set({ 'n', 'x' }, '<leader>aa', function() require('opencode').ask('@this ', { submit = true }) end, { desc = 'Ask opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>as', function() require('opencode').select() end, { desc = 'Select opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ao', function() return require('opencode').operator('@this ') end, { desc = 'Add range to opencode', expr = true })
    vim.keymap.set('n', '<leader>aO', function() return require('opencode').operator('@this ' .. '_') end, { desc = 'Add line to opencode', expr = true })
    vim.keymap.set('n', '<leader>a.', toggle_opencode_terminal, { desc = 'Toggle opencode terminal' })
  end,
  config = function()
    -- Work around opencode.nvim scheduling Server.disconnect as an unbound method.
    local Server = require 'opencode.server'
    local disconnect = Server.disconnect
    Server.disconnect = function(self)
      if self == nil then
        self = Server.connected
      end
      if self == nil then
        return
      end
      return disconnect(self)
    end

    local server_opts = require('opencode.config').opts.server
    server_opts.start = open_opencode_terminal
    server_opts.toggle = toggle_opencode_terminal

    -- snacks integration
    local function opencode_send(...)
      return require('opencode').snacks_picker_send(...)
    end

    local snacks = require 'snacks'
    snacks.config.picker.actions = snacks.config.picker.actions or {}
    snacks.config.picker.actions.opencode_send = opencode_send
    snacks.config.picker.win = snacks.config.picker.win or {}
    snacks.config.picker.win.input = snacks.config.picker.win.input or {}
    snacks.config.picker.win.input.keys = snacks.config.picker.win.input.keys or {}
    snacks.config.picker.win.input.keys['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } }
  end,
}
