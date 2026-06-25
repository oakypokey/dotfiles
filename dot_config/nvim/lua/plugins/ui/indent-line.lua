-- Add indentation guides even on blank lines

local repo = require 'tooling.repos'
local perf = require 'util.perf'

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
return repo.spec('indent_line', {
  event = 'BufReadPost',
  main = 'ibl',
  config = function()
    local ibl = require 'ibl'

    ibl.setup {}

    local function set_buffer(bufnr, enabled)
      ibl.setup_buffer(bufnr, { enabled = enabled })
    end

    local function guard_buffer(bufnr)
      if perf.is_expensive_feature_buffer(bufnr) then
        set_buffer(bufnr, false)
        perf.notify_skip_once(bufnr, 'perf_ibl_skip_notified', 'Indent guides skipped for expensive buffer')
      end
    end

    local function enable_current_buffer()
      local bufnr = vim.api.nvim_get_current_buf()
      perf.confirm_with_progress('Indent guides current buffer', 'Indent guides can slow rendering in expensive buffers. Enable for current buffer?', function()
        set_buffer(bufnr, true)
      end)
    end

    local function enable_project_buffers()
      perf.confirm_with_progress('Indent guides loaded project buffers', 'Enable indent guides for all loaded buffers in this project?', function()
        local count = 0
        for _, bufnr in ipairs(perf.project_buffers()) do
          set_buffer(bufnr, true)
          count = count + 1
        end
        vim.notify(string.format('Indent guides enabled for %d loaded project buffers', count), vim.log.levels.INFO)
      end)
    end

    vim.keymap.set('n', '<leader>pib', enable_current_buffer, { desc = 'Performance: Indent guides current buffer' })
    vim.keymap.set('n', '<leader>pip', enable_project_buffers, { desc = 'Performance: Indent guides loaded project buffers' })

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'TermOpen' }, {
      group = vim.api.nvim_create_augroup('perf-indent-line', { clear = true }),
      callback = function(args) guard_buffer(args.buf) end,
    })

    guard_buffer(vim.api.nvim_get_current_buf())
  end,
})
