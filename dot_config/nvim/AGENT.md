# Neovim Config Agent Guide

This config is managed by chezmoi at `dot_config/nvim` and becomes `~/.config/nvim` when applied.

## Startup Order

`init.lua` loads modules in this order:

1. `core.intro`
2. `core.foundation`
3. `core.keymaps`
4. `core.pack`
5. `plugins`

`core.pack` bootstraps `zpack.nvim` through Neovim's built-in `vim.pack`. Plugin installation and updates are handled by `vim.pack`; lazy-loading and plugin specs are handled by `zpack.nvim`.

Useful plugin commands from comments in `core.pack`:

- Inspect plugin state: `:lua vim.pack.update(nil, { offline = true })`
- Update plugins: `:lua vim.pack.update()`

## Plugin Organization

Plugin specs live under `lua/plugins/` and are grouped by feature area:

- `completion/`
- `dap/`
- `diagnostics/`
- `editing/`
- `formatting/`
- `git/`
- `integrations/`
- `lsp/`
- `navigation/`
- `ui/`

Each plugin file should return a zpack-compatible spec table, or a list/nested list of spec tables. Keep one plugin or closely-related plugin group per file.

Use `tooling.repos` for repository definitions instead of hardcoding plugin repository strings in each spec. Add a key to `lua/tooling/repos.lua`, then use `repo.spec('<key>', overrides)` from plugin files.

Example:

```lua
local repo = require 'tooling.repos'

return repo.spec('colorscheme', {
  priority = 1000,
  config = function()
    require('nordic').load()
  end,
})
```

`tooling.repos.spec` deep-copies the registered repo entry and merges overrides with `vim.tbl_extend('force', ...)`.

## How Plugins Are Loaded

`lua/plugins/init.lua` is the plugin loader.

It does the following:

1. Requires `lang` first so language modules can register LSP servers, Mason tools, formatters, linters, parsers, DAP setup, and test adapters before plugin setup runs.
2. Recursively scans `lua/plugins/**` for `.lua` files, excluding `init.lua`.
3. Converts each file path into a Lua module name.
4. Sorts all plugin files by path for deterministic loading.
5. Requires each plugin module and flattens returned specs into one `specs` list.
6. Calls `require('zpack').setup { defaults = { confirm = false }, spec = specs }`.

A returned table is treated as a plugin spec when it has one of these fields/shapes:

- First array item is a string, such as `{ 'owner/repo' }`
- `src`
- `dir`
- `url`
- `import`
- `name`

Otherwise, the loader recursively treats the returned table as a list of specs.

## Language And Tooling Registry

Language-specific setup lives in `lua/lang/`.

`lua/lang/init.lua` explicitly requires each language module. When adding a new language file, also add it to the `languages` list there.

Language modules should register capabilities through `tooling.registry` rather than configuring shared plugins directly. The shared plugins consume the registry later.

Common registry APIs:

- `registry.lsp_server(name, config)` registers an LSP server and its Mason package.
- `registry.lsp_code_action(action)` adds custom LSP code actions.
- `registry.mason_tool(name)` ensures an arbitrary Mason tool is installed.
- `registry.linter(filetype, names, opts)` registers nvim-lint linters and Mason tools.
- `registry.formatter(filetype, names, opts)` registers conform formatters and Mason tools.
- `registry.format_on_save(filetype)` enables format-on-save for a filetype.
- `registry.treesitter(names)` registers Tree-sitter parsers.
- `registry.dap_tool(name)`, `registry.dap_dependency(...)`, `registry.dap_handler(...)`, and `registry.dap_setup(fn)` register DAP tools and setup hooks.
- `registry.test_dependency(...)` and `registry.test_adapter(fn)` register neotest dependencies and adapters.

This means language files describe language needs, while plugin files under `lua/plugins/` wire those collected needs into Mason, LSP, DAP, formatting, linting, Tree-sitter, and testing plugins.

## Adding A Plugin

1. Add the repository to `lua/tooling/repos.lua` if it is reusable or should have a stable key.
2. Create a spec file in the appropriate `lua/plugins/<area>/` directory.
3. Return `repo.spec('<key>', { ... })` from the spec file.
4. Use zpack lazy-loading fields such as `event`, `cmd`, `keys`, and `ft` where appropriate.
5. Put language-specific tool registration in `lua/lang/<language>.lua`, not in generic plugin specs.

## Conventions

- Keep specs declarative and small.
- Prefer adding repository keys to `tooling.repos` over repeating repository strings.
- Prefer registering language behavior through `tooling.registry` so shared plugins stay centralized.
- Do not manually edit `nvim-pack-lock.json` unless intentionally updating pinned plugin state.
- Preserve deterministic loading: plugin file names and paths affect sorted load order.
