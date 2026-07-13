local M = {}

local deno_markers = { 'deno.json', 'deno.jsonc' }
local node_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' }

local function normalize(path)
  if not path then return nil end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function has_marker(dir, markers)
  for _, marker in ipairs(markers) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, marker)) then return true end
  end
  return false
end

function M.find(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return nil end

  local dir = normalize(vim.fs.dirname(path))
  while dir do
    if has_marker(dir, deno_markers) then return { kind = 'deno', root = dir } end
    if has_marker(dir, node_markers) then return { kind = 'node', root = dir } end

    local parent = normalize(vim.fs.dirname(dir))
    if not parent or parent == dir then return nil end
    dir = parent
  end

  return nil
end

function M.same_root(left, right) return normalize(left) == normalize(right) end

return M
