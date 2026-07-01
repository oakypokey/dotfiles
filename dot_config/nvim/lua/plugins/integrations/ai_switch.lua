local M = {}

local shared_keys = {
  { mode = 'n', lhs = '<leader>aa' },
  { mode = 'x', lhs = '<leader>aa' },
  { mode = 'n', lhs = '<leader>as' },
  { mode = 'x', lhs = '<leader>as' },
  { mode = 'n', lhs = '<leader>ao' },
  { mode = 'x', lhs = '<leader>ao' },
  { mode = 'n', lhs = '<leader>aO' },
  { mode = 'n', lhs = '<leader>ab' },
  { mode = 'n', lhs = '<leader>am' },
  { mode = 'n', lhs = '<leader>ar' },
  { mode = 'n', lhs = '<leader>aC' },
  { mode = 'n', lhs = '<leader>ax' },
  { mode = 'n', lhs = '<leader>aA' },
  { mode = 'n', lhs = '<leader>ad' },
  { mode = 'n', lhs = '<C-.>' },
  { mode = 't', lhs = '<C-.>' },
}

local cleanup = {}

local function pcall_cmd(cmd)
  pcall(function() vim.cmd(cmd) end)
end

cleanup.claudecode = function()
  local ok, claudecode = pcall(require, 'integrations.claudecode')
  if ok and type(claudecode.stop) == 'function' then
    claudecode.stop()
  else
    pcall_cmd 'ClaudeCodeStop'
    pcall_cmd 'ClaudeCodeClose'
  end
end

cleanup.opencode = function()
  local ok, opencode = pcall(require, 'opencode')
  if ok and type(opencode.disconnect) == 'function' then pcall(opencode.disconnect) end

  local ok_terminal, terminal = pcall(require, 'snacks.terminal')
  if ok_terminal then
    local win = terminal.get('opencode --port', { create = false })
    if win then pcall(function() win:close() end) end
  end
end

local function clear_ai_keys()
  for _, key in ipairs(shared_keys) do
    pcall(vim.keymap.del, key.mode, key.lhs)
  end
end

local function load_plugin(name)
  local plugin = require('zpack').get_plugin(name)
  if not plugin then return end
  if plugin.status ~= 'loaded' then vim.cmd.packadd(name) end
end

local setup = {
  ['claudecode.nvim'] = function() require('integrations.claudecode').setup(nil, require('integrations.claudecode').opts) end,
  ['opencode.nvim'] = function() require('integrations.opencode').setup() end,
}

function M.switch(name)
  local other = name == 'opencode.nvim' and 'claudecode.nvim' or 'opencode.nvim'

  cleanup[other:gsub('%.nvim$', '')]()
  clear_ai_keys()
  vim.g.ai_integration = name:gsub('%.nvim$', '')
  load_plugin(name)
  setup[name]()

  vim.notify('Using ' .. (name == 'opencode.nvim' and 'opencode' or 'Claude Code'), vim.log.levels.INFO)
end

function M.setup()
  vim.keymap.set('n', '<leader>tc', function() M.switch 'claudecode.nvim' end, { desc = 'Use Claude Code integration' })
  vim.keymap.set('n', '<leader>to', function() M.switch 'opencode.nvim' end, { desc = 'Use opencode integration' })
end

return M
