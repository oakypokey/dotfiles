local M = {}

local function get_models()
  local path = vim.fn.expand '~/.claude/settings.json'
  if vim.fn.filereadable(path) == 0 then return nil end

  local ok, data = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok then return nil end

  local env = data and data.env or {}
  local models = {}

  for _, key in ipairs {
    'ANTHROPIC_MODEL',
    'ANTHROPIC_DEFAULT_SONNET_MODEL',
    'ANTHROPIC_DEFAULT_OPUS_MODEL',
    'ANTHROPIC_DEFAULT_HAIKU_MODEL',
    'ANTHROPIC_SMALL_FAST_MODEL',
    'CLAUDE_CODE_SUBAGENT_MODEL',
  } do
    local model = env[key]
    if model then
      local exists = false
      for _, item in ipairs(models) do
        if item.value == model then
          exists = true
          break
        end
      end

      if not exists then table.insert(models, { name = model, value = model }) end
    end
  end

  return #models > 0 and models or nil
end

M.cmds = {
  'ClaudeCode',
  'ClaudeCodeFocus',
  'ClaudeCodeSelectModel',
  'ClaudeCodeAdd',
  'ClaudeCodeSend',
  'ClaudeCodeSendText',
  'ClaudeCodeTreeAdd',
  'ClaudeCodeStatus',
  'ClaudeCodeStart',
  'ClaudeCodeStop',
  'ClaudeCodeOpen',
  'ClaudeCodeClose',
  'ClaudeCodeDiffAccept',
  'ClaudeCodeDiffDeny',
  'ClaudeCodeCloseAllDiffs',
}

M.opts = {
  focus_after_send = true,
  terminal = {
    provider = 'snacks',
    split_side = 'right',
    snacks_win_opts = {
      enter = false,
    },
  },
}

function M.stop()
  pcall(function() vim.cmd.ClaudeCodeStop() end)
  pcall(function() vim.cmd.ClaudeCodeClose() end)

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == 'terminal' then
      local name = vim.api.nvim_buf_get_name(bufnr):lower()
      if name:match('claude') then pcall(vim.api.nvim_buf_delete, bufnr, { force = true }) end
    end
  end
end

function M.setup(_, opts)
  opts = vim.tbl_deep_extend('force', {}, M.opts, opts or {})
  opts.models = get_models() or opts.models
  require('claudecode').setup(opts)

  vim.keymap.set('x', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send selection to Claude Code' })
  vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = 'Resume Claude Code' })
  vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = 'Continue Claude Code' })
  vim.keymap.set('n', '<leader>ax', M.stop, { desc = 'Stop Claude Code' })
  vim.keymap.set('n', '<leader>aA', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'Accept Claude Code diff' })
  vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'Deny Claude Code diff' })
  vim.keymap.set({ 'n', 't' }, '<C-.>', '<cmd>ClaudeCodeFocus<cr>', { desc = 'Toggle Claude Code' })
end

return M
