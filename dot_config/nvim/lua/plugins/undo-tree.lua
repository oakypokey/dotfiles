vim.pack.add({
	{ src = "https://github.com/mbbill/undotree", name = "undotree" },
}, { load = false })

vim.keymap.set("n", "<leader>u", function()
	vim.pack.load({ "undotree" })
	vim.cmd.UndoTreeToggle()
end, {
	desc = "Toggle UndoTree",
})
