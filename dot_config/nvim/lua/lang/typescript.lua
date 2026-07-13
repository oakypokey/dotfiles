local registry = require 'tooling.registry'
local js_project = require 'util.js_project'

local filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }

local function reuse_same_root(name)
  return function(client, config) return client.name == name and js_project.same_root(client.root_dir, config.root_dir) end
end

registry.lsp_server('ts_ls', {
  mason = 'typescript-language-server',
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = filetypes,
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local project = js_project.find(bufnr)
    if not project or project.kind == 'deno' then return end

    on_dir(project.root)
  end,
  reuse_client = reuse_same_root 'ts_ls',
  single_file_support = false,
})

registry.lsp_server('denols', {
  mason = 'deno',
  cmd = { 'deno', 'lsp' },
  filetypes = filetypes,
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local project = js_project.find(bufnr)
    if not project or project.kind ~= 'deno' then return end

    on_dir(project.root)
  end,
  reuse_client = reuse_same_root 'denols',
})

registry.treesitter { 'javascript', 'typescript', 'tsx' }

registry.dap_tool 'js-debug-adapter'
registry.dap_setup(function(context)
  local dap = require 'dap'
  local dap_utils = require 'dap.utils'
  local js_debug_adapter = context.mason_package_path('js-debug-adapter', 'js-debug/src/dapDebugServer.js')

  if js_debug_adapter then
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = { js_debug_adapter, '${port}' },
      },
    }
  elseif vim.fn.executable 'js-debug-adapter' == 1 then
    dap.adapters['pwa-node'] = {
      type = 'executable',
      command = 'js-debug-adapter',
    }
  end

  local node_configurations = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch current file with Node',
      program = '${file}',
      cwd = '${workspaceFolder}',
      console = 'integratedTerminal',
      internalConsoleOptions = 'neverOpen',
      sourceMaps = true,
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to Node process',
      processId = dap_utils.pick_process,
      cwd = '${workspaceFolder}',
      internalConsoleOptions = 'neverOpen',
      sourceMaps = true,
    },
  }

  local typescript_configurations = vim.deepcopy(node_configurations)
  table.insert(typescript_configurations, 1, {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch current file with Bun',
    runtimeExecutable = 'bun',
    runtimeArgs = { 'run' },
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
    internalConsoleOptions = 'neverOpen',
    sourceMaps = true,
  })
  table.insert(typescript_configurations, 2, {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch current file with tsx',
    runtimeExecutable = context.local_or_global_command 'tsx',
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
    internalConsoleOptions = 'neverOpen',
    sourceMaps = true,
  })
  table.insert(typescript_configurations, 3, {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch current file with ts-node',
    runtimeExecutable = context.local_or_global_command 'ts-node',
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
    internalConsoleOptions = 'neverOpen',
    sourceMaps = true,
  })
  table.insert(typescript_configurations, {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch current file with Deno',
    runtimeExecutable = 'deno',
    runtimeArgs = { 'run', '-A', '--inspect-brk' },
    runtimeVersion = 'deno',
    program = '${file}',
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
    internalConsoleOptions = 'neverOpen',
    sourceMaps = true,
  })
  table.insert(typescript_configurations, {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to Deno process',
    address = '127.0.0.1',
    port = 9229,
    cwd = '${workspaceFolder}',
    internalConsoleOptions = 'neverOpen',
    sourceMaps = true,
  })

  for _, language in ipairs { 'javascript', 'javascriptreact' } do
    dap.configurations[language] = node_configurations
  end

  for _, language in ipairs { 'typescript', 'typescriptreact' } do
    dap.configurations[language] = typescript_configurations
  end
end)

registry.test_dependency 'neotest_jest'
registry.test_dependency 'neotest_vitest'
registry.test_dependency 'neotest_bun'
registry.test_dependency 'neotest_deno'

local deno_markers = { 'deno.lock', 'deno.json', 'deno.jsonc', 'import_map.json' }
local bun_markers = { 'bun.lock', 'bun.lockb', 'bunfig.toml' }
local vitest_markers = {
  'vitest.config.ts',
  'vitest.config.js',
  'vitest.config.mts',
  'vite.config.ts',
  'vite.config.js',
}
local jest_markers = {
  'jest.config.js',
  'jest.config.ts',
  'jest.config.mjs',
  'jest.config.cjs',
}
local js_markers = vim.list_extend(vim.list_extend(vim.list_extend({}, deno_markers), bun_markers), vim.list_extend(vim.deepcopy(jest_markers), vitest_markers))

registry.test_adapter(function(context)
  if not context.has_marker(jest_markers) then return nil end
  return context.guarded_adapter(
    require 'neotest-jest' {
      jestCommand = 'npm test --',
      cwd = function(path) return context.nearest_root(path or context.current_path(), jest_markers) or vim.fn.getcwd() end,
    },
    jest_markers
  )
end)

registry.test_adapter(function(context)
  if not context.has_marker(vitest_markers) then return nil end
  return context.guarded_adapter(require 'neotest-vitest', vitest_markers)
end)

registry.test_adapter(function(context)
  if not context.has_marker(bun_markers) then return nil end
  return context.guarded_adapter(require 'neotest-bun' { test_command = 'bun test' }, bun_markers)
end)

registry.test_adapter(function(context)
  if not context.has_marker(deno_markers) then return nil end
  return context.guarded_adapter(
    require 'neotest-deno' {
      dap_adapter = 'pwa-node',
      root_files = deno_markers,
    },
    deno_markers
  )
end)

registry.test_adapter(function(context)
  context.filetype_markers.javascript = js_markers
  context.filetype_markers.javascriptreact = js_markers
  context.filetype_markers.typescript = js_markers
  context.filetype_markers.typescriptreact = js_markers
end)
