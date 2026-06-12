-- Depends on plenary.nvim and telescope.nvim.

local repo = require 'tooling.repos'

return repo.spec('harpoon', {
  version = 'harpoon2',
  dependencies = {
    repo.spec 'plenary',
    repo.spec 'telescope',
  },
  keys = {
    { '<leader>[a', function() require('harpoon'):list():add() end, desc = 'Harpoon: Add file' },
    { '<leader>[1', function() require('harpoon'):list():select(1) end, desc = 'Harpoon: Got to file 1' },
    { '<leader>[2', function() require('harpoon'):list():select(2) end, desc = 'Harpoon: Got to file 2' },
    { '<leader>[3', function() require('harpoon'):list():select(3) end, desc = 'Harpoon: Got to file 3' },
    { '<leader>[4', function() require('harpoon'):list():select(4) end, desc = 'Harpoon: Got to file 4' },
    { '<leader>[p', function() require('harpoon'):list():previous() end, desc = 'Harpoon: Prev file' },
    { '<leader>[n', function() require('harpoon'):list():next() end, desc = 'Harpoon: Next file' },
    {
      '<leader>[e',
      function()
        local harpoon = require 'harpoon'
        local conf = require('telescope.config').values
        local file_paths = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(file_paths, item.value)
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Harpoon',
            finder = require('telescope.finders').new_table { results = file_paths },
            previewer = conf.file_previewer {},
            sorter = conf.generic_sorter {},
          })
          :find()
      end,
      desc = 'Harpoon: Toggle menu (Telescope)',
    },
  },
  config = function()
    -- REQUIRED
    require('harpoon'):setup()
  end,
})
