local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

local dependencies = {
  repo.spec 'mason',
  repo.spec 'mason_dap',
  repo.spec 'dap_ui',
  repo.spec 'nio',
  repo.spec 'dap_virtual_text',
}
vim.list_extend(dependencies, registry.dap.dependencies)

return repo.spec('dap', {
  dependencies = dependencies,
  keys = {
    {
      '<leader>dc',
      function() require('dap').continue() end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>di',
      function() require('dap').step_into() end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function() require('dap').step_over() end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>dO',
      function() require('dap').step_out() end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function() require('dap').toggle_breakpoint() end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = 'Debug: Set Breakpoint',
    },
    {
      '<leader>du',
      function() require('dapui').toggle() end,
      desc = 'Debug: Toggle UI',
    },
    {
      '<leader>dr',
      function() require('dap').run_last() end,
      desc = 'Debug: Run Last',
    },
    {
      '<leader>dt',
      function() require('dap').terminate() end,
      desc = 'Debug: Terminate',
    },
    {
      '<leader>de',
      function() require('dapui').eval(nil, { context = 'repl', enter = true }) end,
      desc = 'Debug: Evaluate Under Cursor',
    },
    {
      '<leader>de',
      function() require('dapui').eval(nil, { context = 'repl', enter = true }) end,
      mode = 'v',
      desc = 'Debug: Evaluate Selection',
    },
    {
      '<leader>dE',
      function()
        local expr = vim.fn.input 'Evaluate expression: '
        if expr ~= '' then require('dapui').eval(expr, { context = 'repl', enter = true }) end
      end,
      desc = 'Debug: Evaluate Prompt',
    },
    {
      '<leader>dh',
      function() require('dap.ui.widgets').hover() end,
      desc = 'Debug: Hover Value',
    },
    {
      '<leader>dR',
      function() require('dap').repl.toggle() end,
      desc = 'Debug: Toggle REPL',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local mason_registry = require 'mason-registry'

    vim.fn.sign_define('DapBreakpoint', {
      text = '⚪',
      texthl = 'DapBreakpointSymbol',
      linehl = 'DapBreakpoint',
      numhl = 'DapBreakpoint',
    })

    vim.fn.sign_define('DapStopped', {
      text = '🔴',
      texthl = 'yellow',
      linehl = 'DapBreakpoint',
      numhl = 'DapBreakpoint',
    })
    vim.fn.sign_define('DapBreakpointRejected', {
      text = '⭕',
      texthl = 'DapStoppedSymbol',
      linehl = 'DapBreakpoint',
      numhl = 'DapBreakpoint',
    })

    require('mason-nvim-dap').setup {
      ensure_installed = {},
      automatic_installation = false,
      automatic_setup = true,
      handlers = registry.dap.handlers,
    }

    local function mason_package_path(package, path)
      local ok, pkg = pcall(mason_registry.get_package, package)
      if not ok or not pkg:is_installed() then return nil end
      return vim.fs.joinpath(pkg:get_install_path(), path)
    end

    local function local_or_global_command(command)
      local local_command = vim.fs.joinpath('${workspaceFolder}', 'node_modules', '.bin', command)
      if vim.fn.executable(local_command) == 1 then return local_command end
      return command
    end

    dapui.setup {
      expand_lines = true,
      controls = { enabled = false }, -- no extra play/step buttons
      floating = { border = 'rounded' },
      -- Set dapui window
      render = {
        max_type_length = 60,
        max_value_lines = 200,
      },
      -- Only one layout: just the "scopes" (variables) list at the bottom
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 1.0 }, -- 100% of this panel is scopes
          },
          size = 15, -- height in lines (adjust to taste)
          position = 'bottom', -- "left", "right", "top", "bottom"
        },
      },
    }

    require('nvim-dap-virtual-text').setup()

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    require('overseer').enable_dap()

    local context = {
      mason_package_path = mason_package_path,
      local_or_global_command = local_or_global_command,
    }

    for _, setup in ipairs(registry.dap.setup) do
      setup(context)
    end
  end,
})
