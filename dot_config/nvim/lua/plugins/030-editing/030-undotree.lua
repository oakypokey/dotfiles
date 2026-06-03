local gh = require 'util.github'

return {
  src = gh('mbbill/undotree'),
  name = 'undotree',
  cmd = 'UndotreeToggle',
  init = function()
    vim.keymap.set('n', '<leader>u', function() vim.cmd.UndotreeToggle() end, { desc = 'Toggle UndoTree' })
  end,
}
