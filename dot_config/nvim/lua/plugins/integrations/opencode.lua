-- opencode.lua
--
-- Brings opencode into neovim
local repo = require 'tooling.repos'

local opencode_cmd = 'opencode --port'
---@type snacks.terminal.Opts
local snacks_terminal_opts = {
  win = {
    position = 'right',
    enter = false,
  },
}

local function normalize_path(path) return vim.fs.normalize(path or ''):gsub('/$', '') end

local function cwd_matches(server) return normalize_path(server.cwd) == normalize_path(vim.fn.getcwd()) end

---@type opencode.Opts
vim.g.opencode_opts = {
  server = {
    start = function()
      local terminal = require 'snacks.terminal'
      local win = terminal.get(opencode_cmd, { create = false })
      if win then
        win:show()
        return
      end
      terminal.open(opencode_cmd, snacks_terminal_opts)
    end,
    stop = function()
      local terminal = require 'snacks.terminal'
      local win = terminal.get(opencode_cmd, { create = false })
      if win then
        win:close()
        return
      end
    end,
    toggle = function() require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts) end,
  },
}

return repo.spec('opencode', {
  version = vim.version.range '*',
  dependencies = {
    repo.spec 'snacks',
  },
  event = 'VeryLazy',
  init = function() end,
  config = function()
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
    local disconnect = Server.disconnect
    Server.disconnect = function(self)
      self = self or Server.connected
      if not self then return end
      return disconnect(self)
    end

    -- Limit manual server selection to the current working directory.
    local select_server = require 'opencode.ui.select_server'
    local original_select_server = select_server.select_server
    select_server.select_server = function(servers)
      local matching_servers = vim.tbl_filter(cwd_matches, servers)
      if #matching_servers == 0 then error('No `opencode` servers found for ' .. vim.fn.getcwd(), 0) end
      return original_select_server(matching_servers)
    end

    -- snacks integration
    local function opencode_send(...) return require('opencode').snacks_picker_send(...) end

    local snacks = require 'snacks'
    snacks.config.picker.actions = snacks.config.picker.actions or {}
    snacks.config.picker.actions.opencode_send = opencode_send
    snacks.config.picker.win = snacks.config.picker.win or {}
    snacks.config.picker.win.input = snacks.config.picker.win.input or {}
    snacks.config.picker.win.input.keys = snacks.config.picker.win.input.keys or {}
    snacks.config.picker.win.input.keys['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } }
  end,
})
