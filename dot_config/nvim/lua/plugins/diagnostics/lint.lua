-- Linting

local repo = require 'tooling.repos'
local registry = require 'tooling.registry'
local perf = require 'util.perf'

return repo.spec('lint', {
  dependencies = {
    repo.spec 'mason',
  },
  event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
  config = function()
    local lint = require 'lint'
    lint.linters_by_ft = registry.lint.linters_by_ft

    local function can_auto_lint(bufnr)
      return vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ''
        and vim.bo[bufnr].modifiable
        and vim.api.nvim_buf_get_name(bufnr) ~= ''
        and not perf.is_expensive_feature_buffer(bufnr)
    end

    local function lint_buffer(bufnr)
      vim.api.nvim_buf_call(bufnr, function() lint.try_lint() end)
    end

    local function lint_current_buffer()
      local bufnr = vim.api.nvim_get_current_buf()
      perf.confirm_with_progress('Lint current buffer', 'Run lint for current buffer now?', function() lint_buffer(bufnr) end)
    end

    local function lint_project_buffers()
      perf.confirm_with_progress('Lint project', 'Run lint for every supported file in this project? This may open files briefly and invoke external tools many times.', function()
        local count = 0
        local files = perf.project_files(0, { filetypes = lint.linters_by_ft })

        for _, file in ipairs(files) do
          local bufnr = vim.fn.bufadd(file.path)
          local was_loaded = vim.api.nvim_buf_is_loaded(bufnr)

          vim.fn.bufload(bufnr)
          if vim.api.nvim_buf_is_loaded(bufnr) then
            vim.bo[bufnr].filetype = vim.bo[bufnr].filetype ~= '' and vim.bo[bufnr].filetype or file.filetype
            lint_buffer(bufnr)
            count = count + 1
            if not was_loaded then vim.cmd.bdelete { bufnr, bang = true } end
          end
        end

        vim.notify(string.format('Lint requested for %d project files', count), vim.log.levels.INFO)
      end)
    end

    vim.keymap.set('n', '<leader>plb', lint_current_buffer, { desc = 'Performance: Lint current buffer' })
    vim.keymap.set('n', '<leader>plp', lint_project_buffers, { desc = 'Performance: Lint project files' })

    -- To allow other plugins to add linters to require('lint').linters_by_ft,
    -- instead set linters_by_ft like this:
    -- lint.linters_by_ft = lint.linters_by_ft or {}
    -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
    --
    -- However, note that this will enable a set of default linters,
    -- which will cause errors unless these tools are available:
    -- {
    --   clojure = { "clj-kondo" },
    --   dockerfile = { "hadolint" },
    --   inko = { "inko" },
    --   janet = { "janet" },
    --   json = { "jsonlint" },
    --   markdown = { "vale" },
    --   rst = { "vale" },
    --   ruby = { "ruby" },
    --   terraform = { "tflint" },
    --   text = { "vale" }
    -- }
    --
    -- You can disable the default linters by setting their filetypes to nil:
    -- lint.linters_by_ft['clojure'] = nil
    -- lint.linters_by_ft['dockerfile'] = nil
    -- lint.linters_by_ft['inko'] = nil
    -- lint.linters_by_ft['janet'] = nil
    -- lint.linters_by_ft['json'] = nil
    -- lint.linters_by_ft['markdown'] = nil
    -- lint.linters_by_ft['rst'] = nil
    -- lint.linters_by_ft['ruby'] = nil
    -- lint.linters_by_ft['terraform'] = nil
    -- lint.linters_by_ft['text'] = nil

    -- Create autocommand which carries out the actual linting
    -- on the specified events.
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function(args)
        -- Only run the linter in buffers that you can modify in order to
        -- avoid superfluous noise, notably within the handy LSP pop-ups that
        -- describe the hovered symbol using Markdown.
        if can_auto_lint(args.buf) then
          lint.try_lint()
        elseif perf.is_expensive_feature_buffer(args.buf) then
          perf.notify_skip_once(args.buf, 'perf_lint_skip_notified', 'Auto lint skipped for expensive buffer')
        end
      end,
    })
  end,
})
