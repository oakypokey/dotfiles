local repo = require 'tooling.repos'
local registry = require 'tooling.registry'
local perf = require 'util.perf'

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================

-- [[ Configure Treesitter ]]
--  Used to highlight, edit, and navigate code
--
--  See `:help nvim-treesitter-intro`

-- NOTE: You can also specify a branch or a specific commit
return repo.spec('treesitter', {
  version = 'main',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function()
    -- Ensure basic parsers are installed
    local parsers = {
      'bash',
      'c',
      'diff',
      'html',
      'query',
      'vim',
      'vimdoc',
    }
    vim.list_extend(parsers, registry.parsers)
    require('nvim-treesitter').install(parsers)

    ---@param buf integer
    ---@param language string
    local function treesitter_try_attach(buf, language)
      -- Check if a parser exists and load it
      if not vim.treesitter.language.add(language) then return end
      -- Enable syntax highlighting and other treesitter features
      vim.treesitter.start(buf, language)

      -- Enable treesitter based folds
      -- For more info on folds see `:help folds`
      -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- vim.wo.foldmethod = 'expr'

      -- Check if treesitter indentation is available for this language, and if so enable it
      -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
      local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

      -- Enable treesitter based indentation
      if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
    end

    local available_parsers = require('nvim-treesitter').get_available()
    local function attach_for_filetype(buf, filetype, opts)
      opts = opts or {}
      if not opts.force and perf.is_expensive_feature_buffer(buf) then
        perf.notify_skip_once(buf, 'perf_treesitter_skip_notified', 'Treesitter skipped for expensive buffer')
        return false
      end

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return false end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end

      return true
    end

    local function force_current_buffer()
      local bufnr = vim.api.nvim_get_current_buf()
      perf.confirm_with_progress('Treesitter current buffer', 'Treesitter can be expensive for large buffers. Run for current buffer?', function()
        attach_for_filetype(bufnr, vim.bo[bufnr].filetype, { force = true })
      end)
    end

    local function force_project_buffers()
      perf.confirm_with_progress('Treesitter loaded project buffers', 'Run Treesitter attach for all loaded buffers in this project?', function()
        local count = 0
        for _, bufnr in ipairs(perf.project_buffers()) do
          local ft = vim.bo[bufnr].filetype
          if ft ~= '' and attach_for_filetype(bufnr, ft, { force = true }) then count = count + 1 end
        end
        vim.notify(string.format('Treesitter requested for %d loaded project buffers', count), vim.log.levels.INFO)
      end)
    end

    vim.keymap.set('n', '<leader>pTb', force_current_buffer, { desc = 'Performance: Treesitter current buffer' })
    vim.keymap.set('n', '<leader>pTp', force_project_buffers, { desc = 'Performance: Treesitter loaded project buffers' })

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args) attach_for_filetype(args.buf, args.match) end,
    })

    if vim.bo.filetype ~= '' then attach_for_filetype(0, vim.bo.filetype) end
  end,
})
