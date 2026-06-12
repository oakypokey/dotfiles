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
  local client = action.client_id and vim.lsp.get_client_by_id(action.client_id)
  local encoding = client and client.offset_encoding or 'utf-16'

  if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, encoding) end

  local command = action.command
  if command and client then client:exec_cmd(type(command) == 'table' and command or action, { bufnr = bufnr }) end
end

local function request_opencode_fix(bufnr)
  local diagnostic = diagnostic_under_cursor(bufnr)
  if not diagnostic then
    vim.notify('No diagnostic under cursor', vim.log.levels.WARN, { title = 'opencode' })
    return
  end

  local line = vim.api.nvim_get_current_line()
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

local function code_action_with_opencode(bufnr)
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

    table.insert(items, {
      title = 'OpenCode: fix @this' .. (diagnostic and (' - ' .. diagnostic.message) or ''),
      opencode = true,
    })

    vim.ui.select(items, {
      prompt = 'Code action',
      format_item = function(item) return item.title or (type(item.command) == 'string' and item.command) or 'Code action' end,
    }, function(choice)
      if not choice then return end

      if choice.opencode then
        request_opencode_fix(bufnr)
      else
        apply_lsp_code_action(choice, bufnr)
      end
    end)
  end)
end

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', function() code_action_with_opencode(event.buf) end, '[G]oto Code [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
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

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})
