local M = {}

local function venv_selector(load)
  if not load and not package.loaded['venv-selector'] then return nil end

  local ok, selector = pcall(require, 'venv-selector')
  if not ok then return nil end
  return selector
end

function M.sync(load)
  local selector = venv_selector(load)
  local python = selector and selector.python() or nil
  local venv = selector and selector.venv() or nil

  vim.g.python_path = python
  vim.g.python_venv = venv

  return python, venv
end

function M.python()
  local python = M.sync(true)
  return python or 'python3'
end

function M.venv()
  if package.loaded['venv-selector'] then
    local _, venv = M.sync(false)
    return venv
  end

  return vim.g.python_venv
end

function M.venv_parent()
  local venv = M.venv()
  if not venv or venv == '' then return nil end
  return vim.fn.fnamemodify(venv, ':h:t')
end

return M
