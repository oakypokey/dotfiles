local repo = require 'tooling.repos'
local registry = require 'tooling.registry'
local perf = require 'util.perf'

local function path_type(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type or nil
end

local function glob_to_pattern(glob) return '^' .. glob:gsub('([%.%+%-%^%$%(%)%%])', '%%%1'):gsub('%*', '.*') .. '$' end

local function has_file(dir, name)
  if name:find('*', 1, true) then
    local pattern = glob_to_pattern(name)

    local found = vim.fs.find(function(candidate, path) return candidate:match(pattern) ~= nil and path_type(vim.fs.joinpath(path, candidate)) == 'file' end, {
      path = dir,
      type = 'file',
      limit = 1,
    })

    return #found > 0
  end

  return path_type(vim.fs.joinpath(dir, name)) == 'file'
end

local filetype_markers = {}
local active_adapters = {}

local ignored_dirs = {
  ['.git'] = true,
  ['.direnv'] = true,
  ['.venv'] = true,
  ['.zpack'] = true,
  ['__pycache__'] = true,
  ['bin'] = true,
  ['build'] = true,
  ['dist'] = true,
  ['node_modules'] = true,
  ['obj'] = true,
  ['out'] = true,
  ['pack'] = true,
  ['site'] = true,
  ['target'] = true,
  ['venv'] = true,
}

local function nearest_root(path, markers)
  local absolute = vim.fs.abspath(path)
  local current = path_type(absolute) == 'directory' and absolute or vim.fs.dirname(absolute)

  while current do
    for _, marker in ipairs(markers or {}) do
      if has_file(current, marker) then return current end
    end

    local parent = vim.fs.dirname(current)
    if parent == current then break end

    current = parent
  end

  return nil
end

local function current_path()
  local file = vim.fn.expand '%:p'
  if file ~= '' then return file end

  return vim.fn.getcwd()
end

local function resolve_test_root(path)
  local absolute = vim.fs.abspath(path ~= '' and path or vim.fn.getcwd())
  local markers = filetype_markers[vim.bo.filetype]

  for _, adapter in ipairs(active_adapters) do
    if adapter.root then
      local ok, root = pcall(adapter.root, absolute)
      if ok and root then return root end
    end
  end

  if not markers then return nil end

  -- Important: no fallback to vim.fs.dirname(absolute).
  -- If no marker exists, there is no test root.
  return nearest_root(absolute, markers)
end

local function run_args(path, extra)
  if extra then return vim.tbl_extend('force', { path }, extra) end

  return path
end

local function run_root_args(path, extra)
  local root = resolve_test_root(path)

  if not root then
    vim.notify('Neotest: not inside a recognised test project', vim.log.levels.WARN)
    return nil
  end

  return vim.tbl_extend('force', { root }, extra or {})
end

local function has_marker(markers) return nearest_root(current_path(), markers) ~= nil end

local function guarded_adapter(adapter, markers)
  local original_root = adapter.root
  local original_filter_dir = adapter.filter_dir

  adapter.root = function(dir)
    local root = nearest_root(dir or current_path(), markers)

    if not root then return nil end

    -- Prefer explicit marker root over adapter fallback.
    -- This prevents ~/.config/nvim or plugin roots from becoming test roots.
    return root
  end

  adapter.filter_dir = function(name, rel_path, root)
    if ignored_dirs[name] then return false end

    if original_filter_dir then return original_filter_dir(name, rel_path, root) end

    return true
  end

  return adapter
end

local function build_adapters()
  local adapters = {}
  local context = {
    current_path = current_path,
    filetype_markers = filetype_markers,
    guarded_adapter = guarded_adapter,
    has_marker = has_marker,
    nearest_root = nearest_root,
  }

  for _, build_adapter in ipairs(registry.testing.adapters) do
    local adapter = build_adapter(context)
    if adapter then table.insert(adapters, adapter) end
  end

  active_adapters = adapters

  return adapters
end

local function run_all_adapter(root)
  for _, adapter in ipairs(active_adapters) do
    if adapter.root then
      local ok, adapter_root = pcall(adapter.root, root)
      if ok and adapter_root == root then return ('%s:%s'):format(adapter.name, root) end
    end
  end

  return nil
end

local function run_all_tests()
  local root = resolve_test_root(current_path())
  if not root then
    vim.notify('Neotest: not inside a recognised test project', vim.log.levels.WARN)
    return
  end

  local adapter = run_all_adapter(root)
  if not adapter then
    vim.notify('Neotest: no adapter found for test project', vim.log.levels.WARN)
    return
  end

  require('neotest').run.run { root, suite = true, adapter = adapter }
end

local function confirm_run_all_tests()
  perf.confirm_with_progress(
    'Neotest run all',
    'Run all tests in the detected test project? This can trigger expensive discovery and external test commands.',
    run_all_tests
  )
end

local function debug_current_file()
  perf.confirm_with_progress('Neotest debug file', 'Debug all tests in the current file? This will load DAP and may run expensive test discovery.', function()
    pcall(vim.cmd, 'ZPack load nvim-dap')
    require('neotest').run.run {
      vim.fn.expand '%:p',
      strategy = 'dap',
    }
  end)
end

local function toggle_watch_file()
  perf.confirm_with_progress(
    'Neotest watch file',
    'Toggle watch mode for the current file? Watchers can be expensive in large projects.',
    function() require('neotest').watch.toggle(run_args(vim.fn.expand '%:p')) end
  )
end

local function toggle_output_panel()
  perf.confirm_with_progress(
    'Neotest output panel',
    'Toggle the Neotest output panel? Rendering large test output can be expensive.',
    function() require('neotest').output_panel.toggle() end
  )
end

local dependencies = {
  repo.spec 'plenary',
  repo.spec 'nio',
  repo.spec 'treesitter',
}
vim.list_extend(dependencies, registry.testing.dependencies)

return repo.spec('testing', {
  dependencies = dependencies,
  keys = {
    {
      '<leader>tr',
      function() require('neotest').run.run() end,
      desc = 'Test: Run Nearest',
    },
    {
      '<leader>tf',
      function()
        local path = vim.fn.expand '%:p'
        require('neotest').run.run(run_args(path))
      end,
      desc = 'Test: Run File',
    },
    {
      '<leader>tA',
      confirm_run_all_tests,
      desc = 'Test: Run All',
    },
    {
      '<leader>td',
      function()
        pcall(vim.cmd, 'ZPack load nvim-dap')

        -- Debug nearest test.
        require('neotest').run.run { strategy = 'dap' }
      end,
      desc = 'Test: Debug Nearest',
    },
    {
      '<leader>tD',
      debug_current_file,
      desc = 'Test: Debug File',
    },
    {
      '<leader>ts',
      function() require('neotest').summary.toggle() end,
      desc = 'Test: Toggle Summary',
    },
    {
      '<leader>to',
      function() require('neotest').output.open { enter = true } end,
      desc = 'Test: Open Output',
    },
    {
      '<leader>tO',
      toggle_output_panel,
      desc = 'Test: Toggle Output Panel',
    },
    {
      '<leader>tw',
      toggle_watch_file,
      desc = 'Test: Watch File',
    },
    {
      '<leader>tx',
      function() require('neotest').run.stop() end,
      desc = 'Test: Stop',
    },
  },
  config = function()
    vim.g.neotest_vstest = {
      dap_settings = {
        type = 'netcoredbg',
      },
    }

    require('neotest').setup {
      adapters = build_adapters(),
      discovery = {
        enabled = false,
      },
      running = {
        concurrent = true,
      },
      summary = {
        enabled = true,
      },
      output = {
        enabled = true,
        open_on_run = 'short',
      },
      quickfix = {
        enabled = true,
        open = false,
      },
    }
  end,
})
