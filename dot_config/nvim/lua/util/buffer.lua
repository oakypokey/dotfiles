local M = {}

---@param bufnr? integer
---@return boolean
function M.is_file_buffer(bufnr)
  bufnr = bufnr or 0
  return vim.bo[bufnr].buftype == ''
end

return M
