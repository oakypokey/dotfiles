local M = {}

M.max_filesize = 1024 * 1024
M.max_lines = 10000

local root_markers = {
  '.git',
  'package.json',
  'pyproject.toml',
  'go.mod',
  'Cargo.toml',
  '*.sln',
  '*.csproj',
  'lua',
}

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

function M.buf_path(bufnr)
  bufnr = bufnr or 0
  local path = vim.api.nvim_buf_get_name(bufnr)
  return path ~= '' and path or nil
end

function M.is_large_buffer(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end

  if vim.api.nvim_buf_line_count(bufnr) > M.max_lines then return true end

  local path = M.buf_path(bufnr)
  if not path then return false end

  local stat = vim.uv.fs_stat(path)
  return stat and stat.size > M.max_filesize or false
end

function M.is_expensive_feature_buffer(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].filetype == 'snacks_terminal' or vim.bo[bufnr].filetype == 'snacks.terminal' then return true end
  if vim.bo[bufnr].buftype == 'terminal' then return true end
  return M.is_large_buffer(bufnr)
end

function M.project_root(bufnr)
  local path = M.buf_path(bufnr or 0) or vim.fn.getcwd()
  return vim.fs.root(path, root_markers) or vim.fn.getcwd()
end

function M.project_buffers(bufnr)
  local root = vim.fs.normalize(M.project_root(bufnr or 0))
  local buffers = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      local path = M.buf_path(buf)
      if path then
        path = vim.fs.normalize(path)
        if path == root or vim.startswith(path, root .. '/') then table.insert(buffers, buf) end
      end
    end
  end

  return buffers
end

function M.project_files(bufnr, opts)
  opts = opts or {}
  local root = M.project_root(bufnr or 0)
  local files = {}

  local function scan(dir)
    for name, type in vim.fs.dir(dir) do
      local path = vim.fs.joinpath(dir, name)
      if type == 'directory' then
        if not ignored_dirs[name] then scan(path) end
      elseif type == 'file' then
        local filetype = vim.filetype.match { filename = path }
        if not opts.filetypes or opts.filetypes[filetype] then
          table.insert(files, { path = path, filetype = filetype })
        end
      end
    end
  end

  scan(root)
  return files, root
end

function M.confirm_expensive(title, message, on_confirm)
  vim.ui.select({ 'Run now', 'Cancel' }, {
    prompt = title .. '\n' .. message,
  }, function(choice)
    if choice == 'Run now' then on_confirm() end
  end)
end

function M.with_progress(title, fn)
  vim.notify(title .. '...', vim.log.levels.INFO)
  local ok, result = pcall(fn)
  if ok then
    vim.notify(title .. ' complete', vim.log.levels.INFO)
  else
    vim.notify(title .. ' failed: ' .. result, vim.log.levels.ERROR)
  end
  return ok, result
end

function M.confirm_with_progress(title, message, fn)
  M.confirm_expensive(title, message, function() M.with_progress(title, fn) end)
end

function M.notify_skip_once(bufnr, key, message)
  bufnr = bufnr or 0
  if vim.b[bufnr][key] then return end
  vim.b[bufnr][key] = true
  vim.notify(message, vim.log.levels.INFO)
end

return M
