local repo = require 'tooling.repos'

return repo.spec('undotree', {
  name = 'undotree',
  cmd = 'UndotreeToggle',
  init = function()
    vim.keymap.set('n', '<leader>u', function() vim.cmd.UndotreeToggle() end, { desc = 'Toggle UndoTree' })
  end,
})
