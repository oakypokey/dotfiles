local M = {}

M.entries = {
  -- Core tooling
  mason = { 'mason-org/mason.nvim' },
  mason_tool_installer = { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
  mason_dap = { 'jay-babu/mason-nvim-dap.nvim' },

  -- LSP
  lsp = { 'neovim/nvim-lspconfig' },
  lsp_status = { 'j-hui/fidget.nvim' },
  lsp_peek = { 'r4ppz/lspeek.nvim' },
  venv_selector = { 'linux-cultist/venv-selector.nvim' },

  -- DAP
  dap = { 'mfussenegger/nvim-dap' },
  dap_ui = { 'rcarriga/nvim-dap-ui' },
  dap_virtual_text = { 'theHamsta/nvim-dap-virtual-text' },
  dap_go = { 'leoluz/nvim-dap-go' },
  dap_dll_autopicker = { src = 'https://git.ramboe.io/ramboe/ramboe-dotnet-utils' },
  dap_python = { 'mfussenegger/nvim-dap-python' },
  overseer = { 'stevearc/overseer.nvim' },

  -- Diagnostics, formatting, testing, parsing
  formatting = { 'stevearc/conform.nvim' },
  lint = { 'mfussenegger/nvim-lint' },
  testing = { 'nvim-neotest/neotest' },
  treesitter = { 'nvim-treesitter/nvim-treesitter' },
  trouble = { 'folke/trouble.nvim' },
  tiny_inline_diagnostic = { 'rachartier/tiny-inline-diagnostic.nvim' },
  workspace_diagnostics = { 'artemave/workspace-diagnostics.nvim' },
  todo_comments = { 'folke/todo-comments.nvim' },
  neotest_python = { 'nvim-neotest/neotest-python' },
  neotest_jest = { 'nvim-neotest/neotest-jest' },
  neotest_vitest = { 'marilari88/neotest-vitest' },
  neotest_bun = { 'jutonz/neotest-bun' },
  neotest_deno = { 'MarkEmmons/neotest-deno' },
  neotest_go = { 'nvim-neotest/neotest-go' },
  neotest_vstest = { 'nsidorenco/neotest-vstest' },

  -- Completion
  blink = { 'saghen/blink.cmp' },
  luasnip = { 'L3MON4D3/LuaSnip' },

  -- UI
  bufferline = { 'akinsho/bufferline.nvim' },
  colorscheme = { 'AlexvZyl/nordic.nvim' },
  guess_indent = { 'NMAC427/guess-indent.nvim' },
  icons = { 'nvim-tree/nvim-web-devicons' },
  indent_line = { 'lukas-reineke/indent-blankline.nvim' },
  mini = { 'nvim-mini/mini.nvim' },
  snacks = { 'folke/snacks.nvim' },
  smear_cursor = { 'sphamba/smear-cursor.nvim' },
  which_key = { 'folke/which-key.nvim' },

  -- Navigation
  telescope = { 'nvim-telescope/telescope.nvim' },
  telescope_fzf = { 'nvim-telescope/telescope-fzf-native.nvim' },
  telescope_ui_select = { 'nvim-telescope/telescope-ui-select.nvim' },
  neo_tree = { 'nvim-neo-tree/neo-tree.nvim' },
  harpoon = { 'ThePrimeagen/harpoon' },

  -- Git
  gitsigns = { 'lewis6991/gitsigns.nvim' },
  lazygit = { 'kdheepak/lazygit.nvim' },

  -- Editing
  auto_reload = { 'ccntrq/autoreload.nvim' },
  autopairs = { 'windwp/nvim-autopairs' },
  gotmpl = { 'ngynkvn/gotmpl.nvim' },
  undotree = { 'mbbill/undotree' },

  -- Integrations
  opencode = { 'nickjvandyke/opencode.nvim' },

  -- Shared dependencies
  plenary = { 'nvim-lua/plenary.nvim' },
  nio = { 'nvim-neotest/nvim-nio' },
  nui = { 'MunifTanjim/nui.nvim' },
}

function M.spec(key, overrides)
  local base = assert(M.entries[key], 'unknown repo key: ' .. key)
  return vim.tbl_extend('force', vim.deepcopy(base), overrides or {})
end

return M
