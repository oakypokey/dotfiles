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
          claudecode_send = function(picker) ---@param picker snacks.Picker
            local claudecode = require 'claudecode'
            local count = 0

            for _, item in ipairs(picker:selected { fallback = true }) do
              local path = Snacks.picker.util.path(item)
              if path and path ~= '' then
                local ok = claudecode.send_at_mention(path, nil, nil, 'snacks-picker')
                if ok then count = count + 1 end
              end
            end

            picker:close()
            vim.notify(('Added %d file(s) to Claude Code context'):format(count), vim.log.levels.INFO)
          end,
        },
        win = {
          input = {
            keys = {
              ['<a-a>'] = { 'claudecode_send', mode = { 'n', 'i' } },
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
