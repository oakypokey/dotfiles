local repo = require 'tooling.repos'
local perf = require 'util.perf'

return repo.spec('tiny_inline_diagnostic', {
  event = 'VeryLazy',
  priority = 1000,
  config = function()
    local tiny = require 'tiny-inline-diagnostic'
    local autocmds = require 'tiny-inline-diagnostic.autocmds'
    local extmarks = require 'tiny-inline-diagnostic.extmarks'
    local renderer = require 'tiny-inline-diagnostic.renderer'

    tiny.setup {
      show_source = {
        enabled = true,
        if_many = true,
      },
      show_code = true,
      multilines = { enabled = true },
      override_open_float = true,
    }

    local function disable_buffer(bufnr)
      autocmds.detach(bufnr, function() extmarks.clear(bufnr) end)
    end

    local function render_buffer(bufnr)
      renderer.safe_render(tiny.config, bufnr)
    end

    local function guard_buffer(bufnr)
      if perf.is_expensive_feature_buffer(bufnr) then
        disable_buffer(bufnr)
        perf.notify_skip_once(bufnr, 'perf_inline_diagnostic_skip_notified', 'Inline diagnostics skipped for expensive buffer')
      end
    end

    local function enable_current_buffer()
      local bufnr = vim.api.nvim_get_current_buf()
      perf.confirm_with_progress('Inline diagnostics current buffer', 'Inline diagnostics can be expensive in large or diagnostic-heavy buffers. Render for current buffer?', function()
        render_buffer(bufnr)
      end)
    end

    local function enable_project_buffers()
      perf.confirm_with_progress('Inline diagnostics loaded project buffers', 'Render inline diagnostics for all loaded buffers in this project?', function()
        local count = 0
        for _, bufnr in ipairs(perf.project_buffers()) do
          render_buffer(bufnr)
          count = count + 1
        end
        vim.notify(string.format('Inline diagnostics rendered for %d loaded project buffers', count), vim.log.levels.INFO)
      end)
    end

    vim.keymap.set('n', '<leader>pdb', enable_current_buffer, { desc = 'Performance: Inline diagnostics current buffer' })
    vim.keymap.set('n', '<leader>pdp', enable_project_buffers, { desc = 'Performance: Inline diagnostics loaded project buffers' })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'DiagnosticChanged', 'TermOpen' }, {
      group = vim.api.nvim_create_augroup('perf-inline-diagnostic', { clear = true }),
      callback = function(args) guard_buffer(args.buf) end,
    })

    guard_buffer(vim.api.nvim_get_current_buf())
  end,
})
