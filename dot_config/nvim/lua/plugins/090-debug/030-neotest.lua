local gh = require("util.github")

local function path_type(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.type or nil
end

local function has_file(dir, name)
	if name:find("*", 1, true) then
		return #vim.fs.find(name, { path = dir, type = "file", limit = 1 }) > 0
	end
	return path_type(vim.fs.joinpath(dir, name)) == "file"
end

local adapter_markers = {
	["neotest-deno"] = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json" },
	["neotest-dotnet"] = { "*.csproj", "*.sln", "global.json" },
	["neotest-go"] = { "go.mod" },
	["neotest-python"] = { "pyproject.toml", "setup.py", "setup.cfg", "tox.ini" },
	["neotest-jest"] = { "package.json" },
}

local filetype_markers = {
	cs = adapter_markers["neotest-dotnet"],
	go = adapter_markers["neotest-go"],
	javascript = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json", "package.json" },
	javascriptreact = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json", "package.json" },
	python = adapter_markers["neotest-python"],
	typescript = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json", "package.json" },
	typescriptreact = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json", "package.json" },
}

local function nearest_root(path, markers)
	local absolute = vim.fs.abspath(path)
	local current = path_type(absolute) == "directory" and absolute or vim.fs.dirname(absolute)
	while current do
		for _, marker in ipairs(markers) do
			if has_file(current, marker) then
				return current
			end
		end

		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end
		current = parent
	end

	return nil
end

local function resolve_test_root(path)
	local absolute = vim.fs.abspath(path ~= "" and path or vim.fn.getcwd())
	local markers = filetype_markers[vim.bo.filetype] or {}
	return nearest_root(absolute, markers) or vim.fs.dirname(absolute)
end

local function run_args(path, extra)
	if extra then
		return vim.tbl_extend("force", { path }, extra)
	end
	return path
end

local function run_root_args(path, extra)
	local args = vim.tbl_extend("force", { resolve_test_root(path) }, extra or {})
	return args
end

local function deno_adapter()
	local neotest_deno = require("neotest-deno")
	local adapter = neotest_deno({
		dap_adapter = "pwa-node",
		root_files = { "package.json" },
	})
	local discover_positions = adapter.discover_positions
	local results = adapter.results

	adapter.discover_positions = function(path)
		local tree = discover_positions(path)
		if not tree or #tree:children() > 0 then
			return tree
		end

		local ok, lines = pcall(vim.fn.readfile, path)
		if not ok then
			return tree
		end

		local nodes = { tree:data() }
		for row, line in ipairs(lines) do
			local name = line:match("Deno%.test%(%s*['\"]([^'\"]+)['\"]")
				or line:match("Deno%.test%(%s*{%s*name%s*=%s*['\"]([^'\"]+)['\"]")
			if name then
				table.insert(nodes, {
					id = path .. "::" .. name,
					name = name,
					path = path,
					range = { row - 1, 0, row - 1, #line },
					type = "test",
				})
			end
		end

		if #nodes == 1 then
			return tree
		end

		return require("neotest.types").Tree.from_list(nodes, function(position)
			return position.id
		end)
	end

	local function add_result(fixed, id, value)
		fixed[id] = value
		local normalized = vim.fs.normalize(id)
		fixed[normalized] = value

		local path, name = id:match("^(.-)::(.*)$")
		if path and name then
			local normalized_path = vim.fs.normalize(path)
			fixed[normalized_path .. "::" .. name] = value

			local clean_name = name:gsub('^"', ""):gsub('"$', "")
			clean_name = vim.split(clean_name, "\r", { plain = true })[1]
			fixed[normalized_path .. "::" .. clean_name] = value
		end
	end

	adapter.results = function(spec, result, tree)
		local parsed = results(spec, result, tree)
		local fixed = {}
		local cwd = spec.cwd and vim.fs.normalize(spec.cwd) or nil
		for id, value in pairs(parsed) do
			add_result(fixed, id, value)

			local path, name = id:match("^(.-)::(.*)$")
			local result_path = path or id
			if cwd and not vim.startswith(result_path, "/") then
				local absolute = vim.fs.normalize(vim.fs.joinpath(cwd, result_path))
				add_result(fixed, name and (absolute .. "::" .. name) or absolute, value)
			end
		end

		for _, node in tree:iter_nodes() do
			local position = node:data()
			if position.type == "file" and not fixed[position.id] then
				local prefix = vim.fs.normalize(position.id) .. "::"
				for id, value in pairs(fixed) do
					if vim.startswith(vim.fs.normalize(id), prefix) then
						fixed[position.id] = value
						break
					end
				end
			end

			if position.type == "test" and fixed[position.id] then
				for parent in node:iter_parents() do
					local parent_position = parent:data()
					if not fixed[parent_position.id] then
						fixed[parent_position.id] = fixed[position.id]
					end
				end
			end
		end

		return fixed
	end

	return adapter
end

return {
	src = gh("nvim-neotest/neotest"),
	dependencies = {
		{ src = gh("nvim-lua/plenary.nvim") },
		{ src = gh("nvim-neotest/nvim-nio") },
		{ src = gh("nvim-treesitter/nvim-treesitter") },
		{ src = gh("nvim-neotest/neotest-python") },
		{ src = gh("nvim-neotest/neotest-jest") },
		{ src = gh("MarkEmmons/neotest-deno") },
		{ src = gh("nvim-neotest/neotest-go") },
		{ src = gh("Issafalcon/neotest-dotnet") },
	},
	keys = {
		{
			"<leader>tr",
			function()
				require("neotest").run.run()
			end,
			desc = "Test: Run Nearest",
		},
		{
			"<leader>tf",
			function()
				local path = vim.fn.expand("%:p")
				require("neotest").run.run(run_args(path))
			end,
			desc = "Test: Run File",
		},
		{
			"<leader>tA",
			function()
				require("neotest").run.run(run_root_args(vim.fn.expand("%:p")))
			end,
			desc = "Test: Run All",
		},
		{
			"<leader>td",
			function()
				pcall(vim.cmd, "ZPack load nvim-dap")
				require("neotest").run.run(run_args(vim.fn.expand("%:p"), { strategy = "dap" }))
			end,
			desc = "Test: Debug Nearest",
		},
		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Test: Toggle Summary",
		},
		{
			"<leader>to",
			function()
				require("neotest").output.open({ enter = true })
			end,
			desc = "Test: Open Output",
		},
		{
			"<leader>tO",
			function()
				require("neotest").output_panel.toggle()
			end,
			desc = "Test: Toggle Output Panel",
		},
		{
			"<leader>tw",
			function()
				require("neotest").watch.toggle(run_args(vim.fn.expand("%:p")))
			end,
			desc = "Test: Watch File",
		},
		{
			"<leader>tx",
			function()
				require("neotest").run.stop()
			end,
			desc = "Test: Stop",
		},
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-python")({
					dap = { justMyCode = false },
				}),
				require("neotest-jest")({
					jestCommand = "npm test --",
				}),
				require("neotest-go")({
					experimental = {
						test_table = true,
					},
				}),
				require("neotest-dotnet")({
					dap = {
						adapter_name = "coreclr",
					},
				}),
				deno_adapter(),
			},
			discovery = {
				enabled = true,
				concurrent = 0,
			},
		})
	end,
}
