local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================

-- [[ Formatting ]]
return repo.spec('formatting', {
  dependencies = {
    repo.spec 'mason',
  },
  event = 'BufWritePre',
  keys = {
    {
      '<leader>f',
      function() require('conform').format { async = true, lsp_format = 'fallback' } end,
      mode = { 'n', 'v' },
      desc = 'Format buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      if registry.formatting.format_on_save[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    formatters_by_ft = registry.formatting.formatters_by_ft,
  },
})
