vim.pack.add({
	{
		src = 'https://github.com/nvim-lua/plenary.nvim', name = 'plenary.nvim'
	},
	{
		src = 'https://github.com/ThePrimeagen/harpoon', name = 'harpoon', version = 'harpoon2'
	}
})

local harpoon = require('harpoon')

-- REQUIRED
harpoon:setup();

local conf = require('telescope.config').values
local function toggle_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end

		require('telescope.pickers').new({}, {
		prompt_title = 'Harpoon',
		finder = require('telescope.finders').new_table({results = file_paths}),
		previewer = conf.file_previewer({}),
		sorter = conf.generic_sorter({}),
	}):find()
end

vim.keymap.set('n', '<leader>[a', function() harpoon:list():add() end, { desc = 'Harpoon: Add file'})
vim.keymap.set('n', '<leader>[e', function() toggle_telescope(harpoon:list()) end, { desc = 'Harpoon: Toggle menu (Telescope)'})

vim.keymap.set('n', '<leader>[1', function() harpoon:list():select(1) end, { desc = 'Harpoon: Got to file 1'})
vim.keymap.set('n', '<leader>[2', function() harpoon:list():select(2) end, { desc = 'Harpoon: Got to file 2'})
vim.keymap.set('n', '<leader>[3', function() harpoon:list():select(3) end, { desc = 'Harpoon: Got to file 3'})
vim.keymap.set('n', '<leader>[4', function() harpoon:list():select(4) end, { desc = 'Harpoon: Got to file 4'})

-- Togle previous & next buffers stored within Harpoon list
vim.keymap.set('n', '<leader>[p', function() harpoon:list():previous() end, { desc = 'Harpoon: Prev file'})
vim.keymap.set('n', '<leader>[n', function() harpoon:list():next() end, { desc = 'Harpoon: Next file'})
