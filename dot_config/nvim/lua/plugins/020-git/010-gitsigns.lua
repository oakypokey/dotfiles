local gh = require 'util.github'

-- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
--
-- See `:help gitsigns` to understand what each configuration key does.
-- Adds git related signs to the gutter, as well as utilities for managing changes
return {
  src = gh('lewis6991/gitsigns.nvim'),
  event = 'BufReadPost',
  config = function()
    require('gitsigns').setup {
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 5,
        ignore_whitespace = false,
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        map('n', '<leader>gj', function() gitsigns.nav_hunk 'next' end, { desc = '[G]it next hunk' })
        map('n', '<leader>gk', function() gitsigns.nav_hunk 'prev' end, { desc = '[G]it previous hunk' })

        -- Actions
        -- visual mode
        map('v', '<leader>ghs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
        map('v', '<leader>ghr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
        -- normal mode
        map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
        map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
        map('n', '<leader>gd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>gD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
        map('n', '<leader>gQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)' })
        map('n', '<leader>gq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)' })
        -- Toggles
        map('n', '<leader>gB', gitsigns.toggle_current_line_blame, { desc = '[G]it toggle show [B]lame line' })
        map('n', '<leader>ge', gitsigns.toggle_deleted, { desc = '[G]it toggle deleted lines' })
        map('n', '<leader>gw', gitsigns.toggle_word_diff, { desc = '[G]it toggle intra-line [w]ord diff' })

        -- Text object
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
      end,
    }
  end,
}
