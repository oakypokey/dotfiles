-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local function priority(path)
  local name = vim.fs.basename(path)
  return tonumber(name:match '^(%d+)%-') or 100
end

local function module_name(path)
  local config = vim.fn.stdpath 'config'
  local lua_prefix = vim.fs.joinpath(config, 'lua') .. '/'
  return path:sub(#lua_prefix + 1):gsub('%.lua$', ''):gsub('/', '.')
end

local function collect(dir, files)
  for name, type in vim.fs.dir(dir) do
    local path = vim.fs.joinpath(dir, name)
    if type == 'directory' then
      collect(path, files)
    elseif name:match '%.lua$' and name ~= 'init.lua' then
      table.insert(files, path)
    end
  end
end

local files = {}
collect(vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'plugins'), files)

table.sort(files, function(a, b)
  local pa = priority(a)
  local pb = priority(b)
  if pa == pb then return a < b end
  return pa < pb
end)

for _, path in ipairs(files) do
  require(module_name(path))
end
