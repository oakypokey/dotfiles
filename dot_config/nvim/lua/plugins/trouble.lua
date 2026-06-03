vim.pack.add({
	{
		src = "https://github.com/folke/trouble.nvim",
		name = "trouble.nvim",
	},
}, { load = false })

local function trouble(mode, opts)
	return function()
		vim.pack.load {'trouble.nvim'}
		require('trouble').setup {}
		require('trouble').toggle(mode, opts)
	end
end

vim.keymap.set('n', '<leader>xx', trouble 'diagnostics', {desc = 'Diagnostics (Trouble)'})
vim.keymap.set('n', '<leader>xX', trouble ('diagnostics', {filter = {buf = 0}}), {desc = 'Buffer Diagnostics (Trouble)'})
vim.keymap.set('n', '<leader>xx', trouble ('symbols', { focus = false }), {desc = 'Diagnostics (Trouble)'})
vim.keymap.set('n', '<leader>xx', trouble ('lsp', { focus = false, win = { position = 'right'} }), {desc = 'LSP Definitions / references / ... (Trouble)'})
vim.keymap.set('n', '<leader>xL', trouble 'loclist', {desc = 'Location List (Trouble)'})
vim.keymap.set('n', '<leader>xx', trouble 'qflist', {desc = 'Quickfix List (Trouble)'})
