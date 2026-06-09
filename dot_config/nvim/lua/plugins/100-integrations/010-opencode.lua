-- opencode.lua
--
-- Brings opencode into neovim
local gh = require 'util.github'

local function cwd_overlaps(server_cwd, nvim_cwd)
  return server_cwd:find(nvim_cwd, 1, true) == 1 or nvim_cwd:find(server_cwd, 1, true) == 1
end

local function curl_json(port, path)
  local cmd = {
    'curl',
    '-s',
    '-S',
    '--fail-with-body',
    '--max-time',
    '1',
    '-H',
    'Accept: application/json',
  }

  if vim.env.OPENCODE_SERVER_PASSWORD then
    vim.list_extend(cmd, { '--user', (vim.env.OPENCODE_SERVER_USERNAME or 'opencode') .. ':' .. vim.env.OPENCODE_SERVER_PASSWORD })
  end

  table.insert(cmd, ('http://localhost:%s%s'):format(port, path))

  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 or result.stdout == '' then
    return nil
  end

  local ok, decoded = pcall(vim.fn.json_decode, result.stdout)
  if not ok then
    return nil
  end

  return decoded
end

local function has_current_opencode_server()
  local pgrep = vim.system({ 'pgrep', '-f', 'opencode.*--port' }, { text = true }):wait()
  if pgrep.code ~= 0 or pgrep.stdout == '' then
    return false
  end

  local pids = vim.split(pgrep.stdout, '\n', { trimempty = true })
  local lsof = vim
    .system({ 'lsof', '-Fpn', '-w', '-iTCP', '-sTCP:LISTEN', '-p', table.concat(pids, ','), '-a', '-P', '-n' }, { text = true })
    :wait()
  if lsof.code ~= 0 or lsof.stdout == '' then
    return false
  end

  local nvim_cwd = vim.fn.getcwd()
  for line in lsof.stdout:gmatch('[^\n]+') do
    local port = line:match('^n.*:(%d+)$')
    if port and curl_json(port, '/global/health') then
      local path = curl_json(port, '/path')
      local server_cwd = path and (path.directory or path.worktree)
      if server_cwd and cwd_overlaps(server_cwd, nvim_cwd) then
        return true
      end
    end
  end

  return false
end

return {
  src = gh('nickjvandyke/opencode.nvim'),
  version = vim.version.range('*'),
  cond = has_current_opencode_server,
  dependencies = {
    { src = gh('folke/snacks.nvim') },
  },
  init = function()
    -- opencode config
    vim.g.opencode_opts = {
      server = {
        start = false,
        stop = false,
        toggle = false,
      },
    }
    vim.o.autoread = true

    vim.keymap.set({ 'n', 'x' }, '<leader>aa', function() require('opencode').ask('@this ', { submit = true }) end, { desc = 'Ask opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>as', function() require('opencode').select() end, { desc = 'Select opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ao', function() return require('opencode').operator('@this ') end, { desc = 'Add range to opencode', expr = true })
    vim.keymap.set('n', '<leader>aO', function() return require('opencode').operator('@this ' .. '_') end, { desc = 'Add line to opencode', expr = true })
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

    require('opencode.server.discovery').get():catch(function(err)
      if err then
        vim.notify(err, vim.log.levels.WARN, { title = 'opencode' })
      end
    end)

    -- snacks integration
    local function opencode_send(...)
      return require('opencode').snacks_picker_send(...)
    end

    require('snacks').setup({
      input = {},
      picker = {
        actions = {
          opencode_send = opencode_send,
        },
        win = {
          input = {
            keys = {
              ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
            },
          },
        },
      },
    })
  end,
}
