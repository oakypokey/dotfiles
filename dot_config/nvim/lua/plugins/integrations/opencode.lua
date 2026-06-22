-- opencode.lua
--
-- Brings opencode into neovim
local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

local opencode_cmd = 'opencode --port'
---@type snacks.terminal.Opts
local snacks_terminal_opts = {
  win = {
    position = 'right',
    enter = false,
  },
}

local function normalize_path(path)
  return vim.fs.normalize(path or ''):gsub('/$', '')
end

local function cwd_matches(server)
  return normalize_path(server.cwd) == normalize_path(vim.fn.getcwd())
end

local function has_matching_server(servers)
  for _, server in ipairs(servers) do
    if cwd_matches(server) then return true end
  end
  return false
end

local function wait_for_opencode_server(callback)
  if not callback then return end

  local function poll()
    if not require('snacks.terminal').get(opencode_cmd, { create = false }) then return end

    require('opencode.server.discovery').get_all()
      :next(function(servers)
        if has_matching_server(servers) then
          callback()
        else
          vim.defer_fn(poll, 3000)
        end
      end)
      :catch(function()
        vim.defer_fn(poll, 3000)
      end)
  end

  poll()
end

---@type opencode.Opts
vim.g.opencode_opts = {
  server = {
    start = function(callback)
      local terminal = require 'snacks.terminal'
      local win = terminal.get(opencode_cmd, { create = false })
      if win then
        win:show()
        wait_for_opencode_server(callback)
        return
      end
      terminal.open(opencode_cmd, vim.tbl_deep_extend('force', snacks_terminal_opts, {
        on_create = function()
          wait_for_opencode_server(callback)
        end,
      }))
    end,
  },
}

-- Optionally show upon submitting prompt
vim.api.nvim_create_autocmd('User', {
  pattern = { 'OpencodeEvent:tui.command.execute' },
  callback = function(args)
    ---@type opencode.server.Event
    local event = args.data.event
    if event.properties.command == 'prompt.submit' then
      local win = require('snacks.terminal').get(opencode_cmd, { create = false })
      if win then win:show() end
    end
  end,
})

local function request_opencode_fix(ctx)
  local bufnr = ctx.bufnr or vim.api.nvim_get_current_buf()
  local diagnostic = ctx.diagnostic
  if not diagnostic then
    vim.notify('No diagnostic under cursor', vim.log.levels.WARN, { title = 'opencode' })
    return
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or ''
  local prompt = table.concat({
    'fix @this',
    '',
    'Diagnostic: ' .. diagnostic.message,
    'Current line: ' .. line,
  }, '\n')

  local promise = require('opencode').prompt(prompt)
  if promise and promise.next then
    promise:next(function()
      if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_call(bufnr, function() vim.cmd.checktime() end) end
    end)
  end

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_call(bufnr, function() vim.cmd.checktime() end) end
  end, 1000)
end

registry.lsp_code_action {
  title = 'OpenCode: fix @this',
  kind = 'quickfix',
  command = 'opencode.fixDiagnostic',
  handler = request_opencode_fix,
}

return repo.spec('opencode', {
  version = vim.version.range '*',
  dependencies = {
    repo.spec 'snacks',
  },
  event = 'VeryLazy',
  init = function()
    -- opencode config
    vim.o.autoread = true

    vim.keymap.set({ 'n', 'x' }, '<leader>aa', function() require('opencode').ask('@this ', { submit = true }) end, { desc = 'Ask opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>as', function() require('opencode').select() end, { desc = 'Select opencode...' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ao', function() return require('opencode').operator '@this ' end, { desc = 'Add range to opencode', expr = true })
    vim.keymap.set('n', '<leader>aO', function() return require('opencode').operator('@this ' .. '_') end, { desc = 'Add line to opencode', expr = true })
    -- Avoid <leader> in terminal mode because Neovim watches for terminal keymaps and delays leader input.
    vim.keymap.set({ 'n', 't' }, '<C-.>', function() require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts) end, { desc = 'Toggle opencode' })
  end,
  config = function()
    -- opencode.nvim schedules Server.disconnect as an unbound method.
    local Server = require 'opencode.server'
    local disconnect = Server.disconnect
    Server.disconnect = function(self)
      if self == nil then self = Server.connected end
      if self == nil then return end
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
