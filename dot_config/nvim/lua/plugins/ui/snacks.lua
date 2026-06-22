local repo = require 'tooling.repos'

return repo.spec('snacks', {
  priority = 0,
  config = function()
    --@type snacks.Config
    local Snacks = require 'snacks'
    Snacks.setup {
      dashboard = { sections = {
        { section = 'header' },
        { section = 'keys' },
      } },
      input = {},
      picker = {
        sources = {},
      },
      explorer = {},
      scope = {},
    }

    local function toggle_explorer()
      local explorer_win = Snacks.picker.get({ source = 'explorer' })[1]
      if explorer_win == nil then
        Snacks.picker.explorer()
      elseif explorer_win:is_focused() then
        Snacks.picker.explorer()
      else
        vim.cmd 'wincmd p'
      end
    end

    vim.keymap.set('n', '\\', toggle_explorer, { desc = 'Toggle/Jump to Snacks Explorer' })
  end,
})
