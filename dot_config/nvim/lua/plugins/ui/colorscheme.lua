local repo = require 'tooling.repos'

-- [[ Colorscheme ]]
-- You can easily change to a different colorscheme.
-- Change the name of the colorscheme plugin below, and then
-- change the command under that to load whatever the name of that colorscheme is.
--
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
return repo.spec('colorscheme', {
  priority = 1000,
  config = function()
    require('nordic').setup {
      italic_comments = false,
      telescope = {
        style = 'classic',
      },
      bright_border = true,
    }

    -- Load the colorscheme here.
    require('nordic').load()
  end,
})
