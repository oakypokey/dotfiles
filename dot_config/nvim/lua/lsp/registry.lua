local M = {
  servers = {},
  tools = {},
}

function M.server(name, config)
  M.servers[name] = config or {}
end

function M.tool(name)
  table.insert(M.tools, name)
end

return M
