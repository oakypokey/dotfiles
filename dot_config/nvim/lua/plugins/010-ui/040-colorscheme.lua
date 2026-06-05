local gh = require 'util.github'

-- [[ Colorscheme ]]
-- You can easily change to a different colorscheme.
-- Change the name of the colorscheme plugin below, and then
-- change the command under that to load whatever the name of that colorscheme is.
--
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
return {
  src = gh('AlexvZyl/nordic.nvim'),
  priority = 1000,
  config = function()
    require('nordic').setup {
      italic_comments = false,
    }

    -- Load the colorscheme here.
    require('nordic').load()
  end,
}
