vim.keymap.set({ 'n', 'x' }, '<C-a>', function() require('opencode').ask('@this ', { submit = true }) end, { desc = 'Ask opencode...' })
vim.keymap.set({ 'n', 'x' }, '<C-x>', function() require('opencode').select() end, { desc = 'Select opencode...' })
vim.keymap.set({ 'n', 'x' }, 'go', function() require('opencode').operator '@this ' end, { desc = 'Add range to opencode', expr = true })
vim.keymap.set('n', 'goo', function() require('opencode').operator('@this ' .. '_') end, { desc = 'Add line to opencode', expr = true })

vim.keymap.set('n', '<leader>u', function()
  vim.pack.load { 'undotree' }
  vim.cmd.UndoTreeToggle()
end, {
  desc = 'Toggle UndoTree',
})
