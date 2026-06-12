local repo = require 'tooling.repos'

local M = {
  mason = { tools = {} },
  lsp = { servers = {}, code_actions = {} },
  dap = { dependencies = {}, handlers = {}, setup = {} },
  lint = { linters_by_ft = {} },
  formatting = { formatters_by_ft = {}, format_on_save = {} },
  parsers = {},
  testing = { dependencies = {}, adapters = {} },
}

local function add_unique(list, value)
  if not value then return end
  if not vim.tbl_contains(list, value) then table.insert(list, value) end
end

local function add_many(list, values)
  if type(values) == 'string' then
    add_unique(list, values)
    return
  end

  for _, value in ipairs(values or {}) do
    add_unique(list, value)
  end
end

function M.mason_tool(name) add_unique(M.mason.tools, name) end

function M.lsp_server(name, config)
  config = vim.deepcopy(config or {})
  M.mason_tool(config.mason or name)
  config.mason = nil
  M.lsp.servers[name] = config
end

function M.lsp_code_action(action) add_unique(M.lsp.code_actions, action) end

function M.dap_tool(name) M.mason_tool(name) end

function M.dap_dependency(repo_key_or_spec)
  local spec = type(repo_key_or_spec) == 'string' and repo.spec(repo_key_or_spec) or repo_key_or_spec
  add_unique(M.dap.dependencies, spec)
end

function M.dap_default_handler(fn) M.dap.handlers[1] = fn end

function M.dap_handler(name, fn) M.dap.handlers[name] = fn end

function M.dap_setup(fn) add_unique(M.dap.setup, fn) end

function M.linter(filetype, names, opts)
  local list = M.lint.linters_by_ft[filetype] or {}
  M.lint.linters_by_ft[filetype] = list
  add_many(list, names)

  if opts and opts.mason == false then return end
  if type(names) == 'string' then
    M.mason_tool((opts and opts.mason) or names)
    return
  end

  for _, name in ipairs(names or {}) do
    M.mason_tool(name)
  end
end

function M.formatter(filetype, names, opts)
  local list = M.formatting.formatters_by_ft[filetype] or {}
  M.formatting.formatters_by_ft[filetype] = list
  add_many(list, names)

  if opts and opts.mason == false then return end
  if type(names) == 'string' then
    M.mason_tool((opts and opts.mason) or names)
    return
  end

  for _, name in ipairs(names or {}) do
    M.mason_tool(name)
  end
end

function M.format_on_save(filetype) M.formatting.format_on_save[filetype] = true end

function M.treesitter(names) add_many(M.parsers, names) end

function M.test_dependency(repo_key_or_spec)
  local spec = type(repo_key_or_spec) == 'string' and repo.spec(repo_key_or_spec) or repo_key_or_spec
  add_unique(M.testing.dependencies, spec)
end

function M.test_adapter(fn) add_unique(M.testing.adapters, fn) end

return M
