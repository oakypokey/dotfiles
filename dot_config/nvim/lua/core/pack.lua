-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, zpack setup
-- ============================================================

-- [[ Intro to `vim.pack` ]]
-- `vim.pack` is a new plugin manager built into Neovim,
--  which provides a Lua interface for installing and managing plugins.
--
--  See `:help vim.pack`, `:help vim.pack-examples` or the
--  excellent blog post from the creator of vim.pack and mini.nvim:
--  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
--
--  To inspect plugin state and pending updates, run
--    :lua vim.pack.update(nil, { offline = true })
--
--  To update plugins, run
--    :lua vim.pack.update()
--
--
--  Throughout the rest of the config there will be examples
--  of how to install and configure plugins using `zpack.nvim`,
--  a thin lazy-loading layer on top of `vim.pack`.
--
--  zpack still uses `vim.pack` underneath, but lets plugin files return
--  declarative specs with lazy-loading triggers like `event`, `cmd`,
--  `keys`, and `ft`.

local gh = require 'util.github'

vim.pack.add { gh 'zuqini/zpack.nvim' }
