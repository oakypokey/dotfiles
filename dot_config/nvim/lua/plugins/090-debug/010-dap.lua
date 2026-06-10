local gh = require("util.github")

return {
	src = gh("mfussenegger/nvim-dap"),
	dependencies = {
		{ src = gh("rcarriga/nvim-dap-ui") },
		{ src = gh("nvim-neotest/nvim-nio") },
		{ src = gh("theHamsta/nvim-dap-virtual-text") },
		{ src = gh("jay-babu/mason-nvim-dap.nvim") },
		{ src = gh("leoluz/nvim-dap-go") },
		{ src = gh("mfussenegger/nvim-dap-python") },
	},
	keys = {
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Debug: Start/Continue",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step Into",
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step Over",
		},
		{
			"<leader>dO",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: Step Out",
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug: Toggle Breakpoint",
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Debug: Set Breakpoint",
		},
		{
			"<leader>du",
			function()
				require("dapui").toggle()
			end,
			desc = "Debug: Toggle UI",
		},
		{
			"<leader>dr",
			function()
				require("dap").run_last()
			end,
			desc = "Debug: Run Last",
		},
		{
			"<leader>dt",
			function()
				require("dap").terminate()
			end,
			desc = "Debug: Terminate",
		},
		{
			"<leader>de",
			function()
				require("dapui").eval(nil, { context = "repl", enter = true })
			end,
			desc = "Debug: Evaluate Under Cursor",
		},
		{
			"<leader>de",
			function()
				require("dapui").eval(nil, { context = "repl", enter = true })
			end,
			mode = "v",
			desc = "Debug: Evaluate Selection",
		},
		{
			"<leader>dE",
			function()
				local expr = vim.fn.input("Evaluate expression: ")
				if expr ~= "" then
					require("dapui").eval(expr, { context = "repl", enter = true })
				end
			end,
			desc = "Debug: Evaluate Prompt",
		},
		{
			"<leader>dh",
			function()
				require("dap.ui.widgets").hover()
			end,
			desc = "Debug: Hover Value",
		},
		{
			"<leader>dR",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Debug: Toggle REPL",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local dap_utils = require("dap.utils")
		local mason_registry = require("mason-registry")

		require("mason-nvim-dap").setup({
			automatic_installation = true,
			handlers = {
				function() end,
			},
			ensure_installed = {
				"debugpy",
				"delve",
				"js-debug-adapter",
				"netcoredbg",
			},
		})

		local function mason_package_path(package, path)
			local ok, pkg = pcall(mason_registry.get_package, package)
			if not ok or not pkg:is_installed() then
				return nil
			end

			return vim.fs.joinpath(pkg:get_install_path(), path)
		end

		local function local_or_global_command(command)
			local local_command = vim.fs.joinpath("${workspaceFolder}", "node_modules", ".bin", command)
			if vim.fn.executable(local_command) == 1 then
				return local_command
			end

			return command
		end

		---@diagnostic disable-next-line: missing-fields
		dapui.setup({
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			---@diagnostic disable-next-line: missing-fields
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})
		require("nvim-dap-virtual-text").setup()

		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close

		-- Install golang specific config
		require("dap-go").setup({
			delve = {
				-- On Windows delve must be run attached or it crashes.
				-- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
				detached = vim.fn.has("win32") == 0,
			},
		})

		local debugpy_python = mason_package_path("debugpy", "venv/bin/python")
		require("dap-python").setup(debugpy_python or "python3")

		pcall(function()
			require("overseer").enable_dap()
		end)

		local netcoredbg = mason_package_path("netcoredbg", "netcoredbg")
		if netcoredbg or vim.fn.executable("netcoredbg") == 1 then
			local netcoredbg_adapter = {
				type = "executable",
				command = netcoredbg or "netcoredbg",
				args = { "--interpreter=vscode" },
				options = {
					detached = false,
				},
			}
			dap.adapters.coreclr = netcoredbg_adapter
			dap.adapters.netcoredbg = netcoredbg_adapter

			local dotnet_configurations = {
				{
					type = "netcoredbg",
					name = "Launch .NET project",
					request = "launch",
					program = function()
						return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					console = "integratedTerminal",
					preLaunchTask = "build",
				},
				{
					type = "netcoredbg",
					name = "Attach to .NET process",
					request = "attach",
					processId = dap_utils.pick_process,
					cwd = "${workspaceFolder}",
				},
			}

			for _, language in ipairs({ "cs", "fsharp", "vb" }) do
				dap.configurations[language] = dotnet_configurations
			end
		end

		local js_debug_adapter = mason_package_path("js-debug-adapter", "js-debug/src/dapDebugServer.js")
		if js_debug_adapter then
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = { js_debug_adapter, "${port}" },
				},
			}
		elseif vim.fn.executable("js-debug-adapter") == 1 then
			dap.adapters["pwa-node"] = {
				type = "executable",
				command = "js-debug-adapter",
			}
		end

		local node_configurations = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch current file with Node",
				program = "${file}",
				cwd = "${workspaceFolder}",
				console = "integratedTerminal",
				internalConsoleOptions = "neverOpen",
				sourceMaps = true,
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach to Node process",
				processId = dap_utils.pick_process,
				cwd = "${workspaceFolder}",
				internalConsoleOptions = "neverOpen",
				sourceMaps = true,
			},
		}

		local typescript_configurations = vim.deepcopy(node_configurations)
		table.insert(typescript_configurations, 1, {
			type = "pwa-node",
			request = "launch",
			name = "Launch current file with Bun",
			runtimeExecutable = "bun",
			runtimeArgs = { "run" },
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		})
		table.insert(typescript_configurations, 2, {
			type = "pwa-node",
			request = "launch",
			name = "Launch current file with tsx",
			runtimeExecutable = local_or_global_command("tsx"),
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		})
		table.insert(typescript_configurations, 3, {
			type = "pwa-node",
			request = "launch",
			name = "Launch current file with ts-node",
			runtimeExecutable = local_or_global_command("ts-node"),
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		})
		table.insert(typescript_configurations, {
			type = "pwa-node",
			request = "launch",
			name = "Launch current file with Deno",
			runtimeExecutable = "deno",
			runtimeArgs = { "run", "-A", "--inspect-brk" },
			runtimeVersion = "deno",
			program = "${file}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		})
		table.insert(typescript_configurations, {
			type = "pwa-node",
			request = "attach",
			name = "Attach to Deno process",
			address = "127.0.0.1",
			port = 9229,
			cwd = "${workspaceFolder}",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		})

		for _, language in ipairs({ "javascript", "javascriptreact" }) do
			dap.configurations[language] = node_configurations
		end

		for _, language in ipairs({ "typescript", "typescriptreact" }) do
			dap.configurations[language] = typescript_configurations
		end
	end,
}
