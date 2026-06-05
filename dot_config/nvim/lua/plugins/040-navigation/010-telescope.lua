local gh = require 'util.github'

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================

-- [[ Fuzzy Finder (files, lsp, etc) ]]
--
-- Telescope is a fuzzy finder that comes with a lot of different things that
-- it can fuzzy find! It's more than just a "file finder", it can search
-- many different aspects of Neovim, your workspace, LSP, and more!
--
-- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
-- so feel free to experiment and see what you like!
--
-- The easiest way to use Telescope, is to start by doing something like:
--  :Telescope help_tags
--
-- After running this command, a window will open up and you're able to
-- type in the prompt window. You'll see a list of `help_tags` options and
-- a corresponding preview of the help.
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?
--
-- This opens a window that shows you all of the keymaps for the current
-- Telescope picker. This is really useful to discover what Telescope can
-- do as well as how to actually do it!

---@type (string|vim.pack.Spec)[]
local dependencies = {
  { src = gh('nvim-lua/plenary.nvim') },
  { src = gh('nvim-telescope/telescope-ui-select.nvim') },
}
if vim.fn.executable('make') == 1 then table.insert(dependencies, { src = gh('nvim-telescope/telescope-fzf-native.nvim'), build = 'make' }) end

-- NOTE: You can install multiple plugins at once
return {
  src = gh('nvim-telescope/telescope.nvim'),
  dependencies = dependencies,
  cmd = 'Telescope',
  keys = {
    { '<leader>sh', function() require('telescope.builtin').help_tags() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() require('telescope.builtin').keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', function() require('telescope.builtin').find_files() end, desc = '[S]earch [F]iles' },
    {
      '<leader>gsf',
      function()
        require('telescope.builtin').find_files {
          find_command = {
            'fd',
            '--type',
            'f',
            '--hidden',
            '--exclude',
            '.git',
            '--exclude',
            'node_modules',
          },
        }
      end,
      desc = '[G]it [S]earch [F]iles',
    },
    { '<leader>ss', function() require('telescope.builtin').builtin() end, desc = '[S]earch [S]elect Telescope' },
    { '<leader>sw', function() require('telescope.builtin').grep_string() end, mode = { 'n', 'v' }, desc = '[S]earch current [W]ord' },
    { '<leader>sg', function() require('telescope.builtin').live_grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>sd', function() require('telescope.builtin').diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sr', function() require('telescope.builtin').resume() end, desc = '[S]earch [R]esume' },
    { '<leader>s.', function() require('telescope.builtin').oldfiles() end, desc = '[S]earch Recent Files ("." for repeat)' },
    { '<leader>sc', function() require('telescope.builtin').commands() end, desc = '[S]earch [C]ommands' },
    { '<leader><leader>', function() require('telescope.builtin').buffers() end, desc = '[ ] Find existing buffers' },
    { 'grr', function() require('telescope.builtin').lsp_references() end, desc = '[G]oto [R]eferences' },
    { 'gri', function() require('telescope.builtin').lsp_implementations() end, desc = '[G]oto [I]mplementation' },
    { 'grd', function() require('telescope.builtin').lsp_definitions() end, desc = '[G]oto [D]efinition' },
    { 'gO', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'Open Document Symbols' },
    { 'gW', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, desc = 'Open Workspace Symbols' },
    { 'grt', function() require('telescope.builtin').lsp_type_definitions() end, desc = '[G]oto [T]ype Definition' },
    {
      '<leader>/',
      function()
        require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end,
      desc = '[/] Fuzzily search in current buffer',
    },
    {
      '<leader>s/',
      function()
        require('telescope.builtin').live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end,
      desc = '[S]earch [/] in Open Files',
    },
    { '<leader>sn', function() require('telescope.builtin').find_files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
  },
  config = function()
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      -- pickers = {}
      extensions = {
        ['ui-select'] = { require('telescope.themes').get_dropdown() },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
  end,
}
