local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================

-- [[ LSP Configuration ]]
-- Language files register servers and tools through tooling.registry before zpack setup.

local function diagnostic_under_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local col = cursor[2]
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

  for _, diagnostic in ipairs(diagnostics) do
    local start_col = diagnostic.col or 0
    local end_col = diagnostic.end_col or start_col
    if col >= start_col and col <= end_col then return diagnostic end
  end

  return diagnostics[1]
end

local function apply_lsp_code_action(action, bufnr)
  if action.handler then
    action.handler({ bufnr = bufnr, diagnostic = diagnostic_under_cursor(bufnr), action = action })
    return
  end

  local client = action.client_id and vim.lsp.get_client_by_id(action.client_id)
  local encoding = client and client.offset_encoding or 'utf-16'

  if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, encoding) end

  local command = action.command
  if command and client then client:exec_cmd(type(command) == 'table' and command or action, { bufnr = bufnr }) end
end

local function code_actions(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local diagnostic = diagnostic_under_cursor(bufnr)
  local range_params = vim.lsp.util.make_range_params(0, 'utf-16')
  local params = vim.tbl_extend('force', range_params, {
    context = { diagnostics = diagnostic and { diagnostic } or vim.diagnostic.get(bufnr) },
  })

  vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', params, function(results)
    local items = {}

    for client_id, result in pairs(results) do
      for _, action in ipairs(result.result or {}) do
        action.client_id = client_id
        table.insert(items, action)
      end
    end

    for _, action in ipairs(registry.lsp.code_actions) do
      table.insert(items, action)
    end

    vim.ui.select(items, {
      prompt = 'Code action',
      format_item = function(item) return item.title or (type(item.command) == 'string' and item.command) or 'Code action' end,
    }, function(choice)
      if choice then apply_lsp_code_action(choice, bufnr) end
    end)
  end)
end

local function setup_code_action_handler()
  local default_handler = vim.lsp.handlers['textDocument/codeAction']

  vim.lsp.handlers['textDocument/codeAction'] = function(err, result, ctx, config)
    result = result or {}

    for _, action in ipairs(registry.lsp.code_actions) do
      table.insert(result, {
        title = action.title,
        kind = action.kind,
        command = {
          command = action.command,
          title = action.title,
        },
      })
    end

    return default_handler(err, result, ctx, config)
  end
end

local function setup_lsp_attach()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', function() code_actions(event.buf) end, '[G]oto Code [A]ction', { 'n', 'x' })
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and vim.bo[event.buf].filetype ~= '' then
        if client:supports_method('workspace/diagnostic', event.buf) then
          vim.lsp.buf.workspace_diagnostics { client_id = client.id }
        elseif client.config.filetypes and client.name ~= 'roslyn_ls' then
          require('workspace-diagnostics').populate_workspace_diagnostics(client, event.buf)
        end
      end

      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })
end

return repo.spec('lsp', {
  dependencies = {
    repo.spec 'mason',
  },
  config = function()
    setup_code_action_handler()
    setup_lsp_attach()

    for name, server in pairs(registry.lsp.servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
})
