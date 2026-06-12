local repo = require 'tooling.repos'

-- [[ Installing and Configuring Plugins ]]
--
-- Plugin files return zpack specs. zpack installs the plugin and handles lazy-loading triggers.
--
-- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
--
-- For example, lets say we want to install `guess-indent.nvim` - a plugin for
-- automatically detecting and setting the indentation.
--
-- This spec installs https://github.com/NMAC427/guess-indent.nvim and calls setup on first buffer read.
return repo.spec('guess_indent', {
  event = 'BufReadPre',
  config = function() require('guess-indent').setup {} end,
})
