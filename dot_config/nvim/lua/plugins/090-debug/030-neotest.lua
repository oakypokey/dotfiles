local gh = require("util.github")

local function path_type(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.type or nil
end

local function glob_to_pattern(glob)
	return "^" .. glob:gsub("([%.%+%-%^%$%(%)%%])", "%%%1"):gsub("%*", ".*") .. "$"
end

local function has_file(dir, name)
	if name:find("*", 1, true) then
		local pattern = glob_to_pattern(name)

		local found = vim.fs.find(function(candidate, path)
			return candidate:match(pattern) ~= nil
				and path_type(vim.fs.joinpath(path, candidate)) == "file"
		end, {
			path = dir,
			type = "file",
			limit = 1,
		})

		return #found > 0
	end

	return path_type(vim.fs.joinpath(dir, name)) == "file"
end

local adapter_markers = {
	["neotest-deno"] = { "deno.lock", "deno.json", "deno.jsonc", "import_map.json" },
	["neotest-bun"] = { "bun.lock", "bun.lockb", "bunfig.toml" },
	["neotest-vitest"] = {
		"vitest.config.ts",
		"vitest.config.js",
		"vitest.config.mts",
		"vite.config.ts",
		"vite.config.js",
	},
	["neotest-vstest"] = { "*.csproj", "*.sln", "global.json" },
	["neotest-go"] = { "go.mod" },
	["neotest-python"] = {
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"tox.ini",
		"pytest.ini",
	},
	["neotest-jest"] = {
		"jest.config.js",
		"jest.config.ts",
		"jest.config.mjs",
		"jest.config.cjs",
	},
}

local js_markers = vim.list_extend(
	vim.list_extend(vim.list_extend({}, adapter_markers["neotest-deno"]), adapter_markers["neotest-bun"]),
	vim.list_extend(vim.deepcopy(adapter_markers["neotest-jest"]), adapter_markers["neotest-vitest"])
)

local filetype_markers = {
	cs = adapter_markers["neotest-vstest"],
	go = adapter_markers["neotest-go"],
	javascript = js_markers,
	javascriptreact = js_markers,
	python = adapter_markers["neotest-python"],
	typescript = js_markers,
	typescriptreact = js_markers,
}

local ignored_dirs = {
	[".git"] = true,
	[".direnv"] = true,
	[".venv"] = true,
	[".zpack"] = true,
	["__pycache__"] = true,
	["bin"] = true,
	["build"] = true,
	["dist"] = true,
	["node_modules"] = true,
	["obj"] = true,
	["out"] = true,
	["pack"] = true,
	["site"] = true,
	["target"] = true,
	["venv"] = true,
}

local function nearest_root(path, markers)
	local absolute = vim.fs.abspath(path)
	local current = path_type(absolute) == "directory" and absolute or vim.fs.dirname(absolute)

	while current do
		for _, marker in ipairs(markers or {}) do
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

local function current_path()
	local file = vim.fn.expand("%:p")
	if file ~= "" then
		return file
	end

	return vim.fn.getcwd()
end

local function resolve_test_root(path)
	local absolute = vim.fs.abspath(path ~= "" and path or vim.fn.getcwd())
	local markers = filetype_markers[vim.bo.filetype]

	if not markers then
		return nil
	end

	-- Important: no fallback to vim.fs.dirname(absolute).
	-- If no marker exists, there is no test root.
	return nearest_root(absolute, markers)
end

local function run_args(path, extra)
	if extra then
		return vim.tbl_extend("force", { path }, extra)
	end

	return path
end

local function run_root_args(path, extra)
	local root = resolve_test_root(path)

	if not root then
		vim.notify("Neotest: not inside a recognised test project", vim.log.levels.WARN)
		return nil
	end

	return vim.tbl_extend("force", { root }, extra or {})
end

local function has_marker(markers)
	return nearest_root(current_path(), markers) ~= nil
end

local function guarded_adapter(adapter, markers)
	local original_root = adapter.root
	local original_filter_dir = adapter.filter_dir

	adapter.root = function(dir)
		local root = nearest_root(dir or current_path(), markers)

		if not root then
			return nil
		end

		-- Prefer explicit marker root over adapter fallback.
		-- This prevents ~/.config/nvim or plugin roots from becoming test roots.
		return root
	end

	adapter.filter_dir = function(name, rel_path, root)
		if ignored_dirs[name] then
			return false
		end

		if original_filter_dir then
			return original_filter_dir(name, rel_path, root)
		end

		return true
	end

	return adapter
end

local function build_adapters()
	local adapters = {}

	if has_marker(adapter_markers["neotest-python"]) then
		table.insert(
			adapters,
			guarded_adapter(
				require("neotest-python")({
					runner = "pytest",
					dap = { justMyCode = false },
					args = { "-q" },
				}),
				adapter_markers["neotest-python"]
			)
		)
	end

	if has_marker(adapter_markers["neotest-jest"]) then
		table.insert(
			adapters,
			guarded_adapter(
				require("neotest-jest")({
					jestCommand = "npm test --",
					cwd = function(path)
						return nearest_root(path or current_path(), adapter_markers["neotest-jest"]) or vim.fn.getcwd()
					end,
				}),
				adapter_markers["neotest-jest"]
			)
		)
	end

	if has_marker(adapter_markers["neotest-vitest"]) then
		table.insert(
			adapters,
			guarded_adapter(require("neotest-vitest"), adapter_markers["neotest-vitest"])
		)
	end

	if has_marker(adapter_markers["neotest-bun"]) then
		table.insert(
			adapters,
			guarded_adapter(
				require("neotest-bun")({
					test_command = "bun test",
				}),
				adapter_markers["neotest-bun"]
			)
		)
	end

	if has_marker(adapter_markers["neotest-go"]) then
		table.insert(
			adapters,
			guarded_adapter(
				require("neotest-go")({
					experimental = {
						test_table = true,
					},
				}),
				adapter_markers["neotest-go"]
			)
		)
	end

	if has_marker(adapter_markers["neotest-vstest"]) then
		table.insert(
			adapters,
			guarded_adapter(require("neotest-vstest"), adapter_markers["neotest-vstest"])
		)
	end

	if has_marker(adapter_markers["neotest-deno"]) then
		table.insert(
			adapters,
			guarded_adapter(
				require("neotest-deno")({
					dap_adapter = "pwa-node",
					root_files = adapter_markers["neotest-deno"],
				}),
				adapter_markers["neotest-deno"]
			)
		)
	end

	return adapters
end

local function run_all_tests()
	local args = run_root_args(current_path())

	if args then
		require("neotest").run.run(args)
	end
end

return {
	src = gh("nvim-neotest/neotest"),
	dependencies = {
		{ src = gh("nvim-lua/plenary.nvim") },
		{ src = gh("nvim-neotest/nvim-nio") },
		{ src = gh("nvim-treesitter/nvim-treesitter") },
		{ src = gh("nvim-neotest/neotest-python") },
		{ src = gh("nvim-neotest/neotest-jest") },
		{ src = gh("marilari88/neotest-vitest") },
		{ src = gh("jutonz/neotest-bun") },
		{ src = gh("MarkEmmons/neotest-deno") },
		{ src = gh("nvim-neotest/neotest-go") },
		{ src = gh("nsidorenco/neotest-vstest") },
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
			run_all_tests,
			desc = "Test: Run All",
		},
		{
			"<leader>td",
			function()
				pcall(vim.cmd, "ZPack load nvim-dap")

				-- Debug nearest test.
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Test: Debug Nearest",
		},
		{
			"<leader>tD",
			function()
				pcall(vim.cmd, "ZPack load nvim-dap")

				-- Debug current file.
				require("neotest").run.run({
					vim.fn.expand("%:p"),
					strategy = "dap",
				})
			end,
			desc = "Test: Debug File",
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
		vim.g.neotest_vstest = {
			dap_settings = {
				type = "netcoredbg",
			},
		}

		require("neotest").setup({
			adapters = build_adapters(),
			discovery = {
				enabled = true,
			},
			running = {
				concurrent = true,
			},
			summary = {
				enabled = true,
			},
			output = {
				enabled = true,
				open_on_run = "short",
			},
			quickfix = {
				enabled = true,
				open = false,
			},
		})
	end,
}
