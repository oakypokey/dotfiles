local gh = require 'util.github'

-- Highlight todo, notes, etc in comments
return {
  src = gh('folke/todo-comments.nvim'),
  event = 'BufReadPost',
  opts = { signs = false },
}
