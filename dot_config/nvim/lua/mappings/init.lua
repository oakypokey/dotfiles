local function priority(path)
  local name = vim.fs.basename(path)
  return tonumber(name:match '^(%d+)%-') or 100
end

local function module_name(path)
  local config = vim.fn.stdpath 'config'
  local lua_prefix = vim.fs.joinpath(config, 'lua') .. '/'
  return path:sub(#lua_prefix + 1):gsub('%.lua$', ''):gsub('/', '.')
end

local files = {}
local mappings_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'mappings')

for name, type in vim.fs.dir(mappings_dir) do
  if type == 'file' and name:match '%.lua$' and name ~= 'init.lua' then
    table.insert(files, vim.fs.joinpath(mappings_dir, name))
  end
end

table.sort(files, function(a, b)
  local pa = priority(a)
  local pb = priority(b)
  if pa == pb then return a < b end
  return pa < pb
end)

for _, path in ipairs(files) do
  require(module_name(path))
end
