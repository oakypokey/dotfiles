local gh = require("util.github")
local registry = require("lsp.registry")

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================

-- [[ LSP Configuration ]]
-- Language files in this folder register their servers and tools through
-- lsp.registry. zpack requires all plugin files before setup, so the registry
-- is populated before this spec's config callback runs.

local specs = {
	{
		src = gh("j-hui/fidget.nvim"),
		config = function()
			require("fidget").setup({})
		end,
	},
}

table.insert(specs, {
	src = gh("neovim/nvim-lspconfig"),
	dependencies = {
		{
			src = gh("mason-org/mason.nvim"),
			config = function()
				require("mason").setup({})
			end,
		},
		{ src = gh("mason-org/mason-lspconfig.nvim") },
		{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
	},
	config = function()
		local ensure_installed = vim.tbl_map(function(name)
			return registry.servers[name].mason or name
		end, vim.tbl_keys(registry.servers))
		vim.list_extend(ensure_installed, registry.tools)

		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		for name, server in pairs(registry.servers) do
			vim.lsp.config(name, server)
			vim.lsp.enable(name)
		end
	end,
})

return specs
