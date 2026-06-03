local gh = require 'util.github'

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================

-- [[ Snippet Engine ]]

-- NOTE: You can also specify plugin using a version range for its git tag.
--  See `:help vim.version.range()` for more info
return {
  src = gh('L3MON4D3/LuaSnip'),
  version = vim.version.range('2.*'),
  event = 'InsertEnter',
  build = vim.fn.executable 'make' == 1 and 'make install_jsregexp' or nil,
  opts = {},
}

-- `friendly-snippets` contains a variety of premade snippets.
--    See the README about individual language/framework/plugin snippets:
--    https://github.com/rafamadriz/friendly-snippets
--
-- return a zpack spec for gh 'rafamadriz/friendly-snippets' to enable these snippets.
-- require('luasnip.loaders.from_vscode').lazy_load()
