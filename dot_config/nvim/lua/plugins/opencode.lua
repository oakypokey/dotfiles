-- opencode.lua
--
-- Brings opencode into neovim
vim.pack.add {
	{
		src = 'https://github.com/nickyjvandyke/opencode.nvim',
		version = vim.version.range '*'
	},
	{
		src = 'https://github.com/folke/snacks.nvim'
	},
}

-- opencode config
vim.g.opencode_opts = {

}

vim.o.autoread = true

-- snacks integration
require('snacks').setup {
	input = {},
	picker = {
		actions = {
			opencode_send = function(...) return require('opencode').snacks_picker_send(...) end,
		},
		win = {
			input = {
				keys = {
					['<a-a>'] = { 'opencode_send', mode = {'n', 'i'}},
				}
			}
		}
	}
}

vim.keymap.set({'n', 'x'}, '<C-a>', function() require('opencode').ask('@this ', {submit = true}) end, {desc = 'Ask opencode...'})
vim.keymap.set({'n', 'x'}, '<C-x>', function() require('opencode').select() end, {desc = 'Select opencode...'})
vim.keymap.set({'n', 'x'}, 'go', function() require('opencode').operator '@this ' end, {desc = 'Add range to opencode', expr = true})
vim.keymap.set('n', 'goo', function() require('opencode').operator ('@this ' .. '_') end, {desc = 'Add line to opencode', expr = true})

