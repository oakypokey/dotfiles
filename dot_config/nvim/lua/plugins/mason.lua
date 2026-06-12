local repo = require 'tooling.repos'
local registry = require 'tooling.registry'

local timeout_ms = 120000

local function wait_for_tools(tools)
  if #tools == 0 then return end

  local mason_registry = require 'mason-registry'
  local deadline = vim.uv.now() + timeout_ms
  local pending = vim.deepcopy(tools)
  local next_notify = 0

  vim.notify(('Mason waiting for %d tools to install...'):format(#pending), vim.log.levels.INFO)

  while #pending > 0 and vim.uv.now() < deadline do
    local next_pending = {}
    local failed = {}

    for _, name in ipairs(pending) do
      local ok, package = pcall(mason_registry.get_package, name)
      if not ok then
        table.insert(failed, name)
      elseif not package:is_installed() then
        table.insert(next_pending, name)
      end
    end

    if #failed > 0 then vim.notify('Mason could not resolve tools: ' .. table.concat(failed, ', '), vim.log.levels.WARN) end

    pending = next_pending
    if #pending > 0 then
      local now = vim.uv.now()
      if now >= next_notify then
        vim.notify(('Mason still waiting for %d tools: %s'):format(#pending, table.concat(pending, ', ')), vim.log.levels.INFO)
        next_notify = now + 5000
      end
      vim.wait(250)
    end
  end

  if #pending > 0 then
    vim.notify('Mason tool install timed out: ' .. table.concat(pending, ', '), vim.log.levels.WARN)
  else
    vim.notify('Mason tools installed', vim.log.levels.INFO)
  end
end

return repo.spec('mason', {
  dependencies = {
    repo.spec 'mason_tool_installer',
  },
  config = function()
    require('mason').setup {}
    require('mason-tool-installer').setup {
      ensure_installed = registry.mason.tools,
      run_on_start = true,
      start_delay = 0,
    }

    wait_for_tools(registry.mason.tools)
  end,
})
