local repo = require 'tooling.repos'
local registry = require 'tooling.registry'
local buffer = require 'util.buffer'

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================

-- [[ LSP Configuration ]]
-- Language files register servers and tools through tooling.registry before zpack setup.

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
      map('gra', function() vim.lsp.buf.code_action() end, '[G]oto Code [A]ction', { 'n', 'x' })
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and buffer.is_file_buffer(event.buf) and vim.bo[event.buf].filetype ~= '' then
        if client:supports_method('workspace/diagnostic', event.buf) then
          vim.lsp.buf.workspace_diagnostics { client_id = client.id }
        elseif client.config.filetypes and client.name ~= 'basedpyright' and client.name ~= 'roslyn_ls' then
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
