local repo = require 'tooling.repos'

-- Highlight todo, notes, etc in comments
return repo.spec('todo_comments', {
  event = 'BufReadPost',
  opts = { signs = false },
})
