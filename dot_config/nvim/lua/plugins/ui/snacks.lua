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
        actions = {
          opencode_send = function(picker) ---@param picker snacks.Picker
            local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
              return item.file and require('opencode').format { path = item.file, from = item.pos, to = item.end_pos } or item.text
            end, picker:selected { fallback = true })

            require('opencode').prompt(table.concat(items, ', ') .. ' ')
          end,
        },
        win = {
          input = {
            keys = {
              ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
            },
          },
        },
      },
      explorer = {},
      scope = {},
      bigfile = {},
      dim = {},
      scroll = {},
      statuscolumn = {},
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
    Snacks.toggle
      .new({
        name = 'Dim',
        get = function() return vim.g.snacks_dim ~= false end,
        set = function(enabled)
          vim.g.snacks_dim = enabled

          if enabled then
            Snacks.dim.enable()
          else
            Snacks.dim.disable()
          end
        end,
      })
      :map '<leader>,d'
  end,
})
