local function trouble(mode, opts)
  return function()
    vim.pack.load { 'trouble.nvim' }
    require('trouble').setup {}
    require('trouble').toggle(mode, opts)
  end
end

vim.keymap.set('n', '<leader>xx', trouble 'diagnostics', { desc = 'Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>xX', trouble('diagnostics', { filter = { buf = 0 } }), { desc = 'Buffer Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>cs', trouble('symbols', { focus = false }), { desc = 'Symbols (Trouble)' })
vim.keymap.set('n', '<leader>cL', trouble('lsp', { focus = false, win = { position = 'right' } }), { desc = 'LSP Definitions / references / ... (Trouble)' })
vim.keymap.set('n', '<leader>xL', trouble 'loclist', { desc = 'Location List (Trouble)' })
vim.keymap.set('n', '<leader>xQ', trouble 'qflist', { desc = 'Quickfix List (Trouble)' })
