# LSP/DAP Language Refactor Plan

## Goals

- Keep `dot_config/nvim/lua/plugins/` as zpack spec-only code.
- Move language-specific behavior into language declaration files.
- Use one shared registry populated before zpack starts.
- Use zpack dependencies and explicit plugin names instead of numeric folder/file prefixes.
- Centralize plugin repository/name mappings so plugins can be replaced by changing one file.
- Let Mason install all external tools once through `mason-tool-installer.nvim`.
- Let `mason-nvim-dap.nvim` run with DAP and perform automatic DAP registration via `automatic_setup`.
- Keep Plenary as a named dependency only, not as a standalone plugin spec.

## Target Layout

```text
dot_config/nvim/lua/
  tooling/
    registry.lua
    repos.lua

  lang/
    init.lua
    csharp.lua
    go.lua
    lua.lua
    markdown.lua
    python.lua
    typescript.lua

  plugins/
    init.lua
    mason.lua

    completion/
      blink.lua
      luasnip.lua

    dap/
      dap.lua
      overseer.lua

    diagnostics/
      lint.lua
      neotest.lua
      tiny-inline-diagnostic.lua
      todo-comments.lua
      trouble.lua
      workspace-diagnostics.lua

    editing/
      auto-reload.lua
      autopairs.lua
      gotmpl.lua
      undotree.lua

    formatting/
      conform.lua

    git/
      gitsigns.lua
      lazygit.lua

    integrations/
      opencode.lua

    lsp/
      lsp.lua
      lspeek.lua

    navigation/
      harpoon.lua
      neo-tree.lua
      telescope.lua

    ui/
      bufferline.lua
      colorscheme.lua
      guess-indent.lua
      icons.lua
      indent-line.lua
      mini.lua
      snacks.lua
      smear-cursor.lua
      treesitter.lua
      which-key.lua
```

## Startup Flow

```text
startup
  -> require('lang')
  -> language modules populate tooling.registry
  -> plugins/init.lua collects zpack specs from plugins/ only
  -> zpack.setup({ spec = specs })
  -> mason spec installs registry.mason.tools via mason-tool-installer
  -> feature specs load by zpack dependency/lazy rules
  -> lsp/dap/lint/formatting/treesitter/neotest consume registry data
```

## Phase 1: Add Support Modules

### Create `tooling/repos.lua`

Purpose:

- Store all repo/name mappings in one place.
- Return deep-copied specs so plugin files can safely add fields.
- Prefer zpack-style positional repo strings plus explicit `name` values.

Initial API:

```lua
local M = {}

M.entries = {
  mason = { 'mason-org/mason.nvim', name = 'mason' },
  mason_tool_installer = { 'WhoIsSethDaniel/mason-tool-installer.nvim', name = 'mason-tool-installer' },
  mason_dap = { 'jay-babu/mason-nvim-dap.nvim', name = 'mason-dap' },

  lsp = { 'neovim/nvim-lspconfig', name = 'lsp' },
  lsp_status = { 'j-hui/fidget.nvim', name = 'lsp-status' },
  lsp_peek = { 'r4ppz/lspeek.nvim', name = 'lsp-peek' },

  dap = { 'mfussenegger/nvim-dap', name = 'dap' },
  dap_ui = { 'rcarriga/nvim-dap-ui', name = 'dap-ui' },
  dap_virtual_text = { 'theHamsta/nvim-dap-virtual-text', name = 'dap-virtual-text' },
  dap_go = { 'leoluz/nvim-dap-go', name = 'dap-go' },
  dap_python = { 'mfussenegger/nvim-dap-python', name = 'dap-python' },

  formatting = { 'stevearc/conform.nvim', name = 'formatting' },
  lint = { 'mfussenegger/nvim-lint', name = 'lint' },
  testing = { 'nvim-neotest/neotest', name = 'testing' },
  treesitter = { 'nvim-treesitter/nvim-treesitter', name = 'treesitter' },

  plenary = { 'nvim-lua/plenary.nvim', name = 'plenary' },
  nio = { 'nvim-neotest/nvim-nio', name = 'nio' },
}

function M.spec(key, overrides)
  local base = assert(M.entries[key], 'unknown repo key: ' .. key)
  return vim.tbl_extend('force', vim.deepcopy(base), overrides or {})
end

return M
```

Expand `M.entries` during migration for every plugin currently using `util.github`.

### Create `tooling/registry.lua`

Purpose:

- Own one shared registry table.
- Provide additive helpers only.
- Dedupe list values.
- Prevent language files from assigning whole sections.

Registry sections:

```lua
local M = {
  mason = { tools = {} },
  lsp = { servers = {} },
  dap = { dependencies = {}, handlers = {}, setup = {} },
  lint = { linters_by_ft = {} },
  formatting = { formatters_by_ft = {}, format_on_save = {} },
  treesitter = { parsers = {} },
  testing = { dependencies = {}, adapters = {} },
}
```

Required helpers:

- `mason_tool(name)`
- `lsp_server(name, config)`
- `dap_tool(name)`
- `dap_dependency(repo_key_or_spec)`
- `dap_default_handler(fn)`
- `dap_handler(name, fn)`
- `dap_setup(fn)`
- `linter(filetype, names, opts)`
- `formatter(filetype, names, opts)`
- `format_on_save(filetype)`
- `treesitter(names)`
- `test_dependency(repo_key_or_spec)`
- `test_adapter(fn)`

Default Mason naming rules:

- `lsp_server(name, config)` adds Mason tool `config.mason or name`, then removes `mason` from the LSP config before storing it.
- `dap_tool(name)` adds Mason tool `name`.
- `linter(filetype, name, opts)` adds Mason tool `opts.mason or name` unless `opts.mason == false`.
- `formatter(filetype, name, opts)` adds Mason tool `opts.mason or name` unless `opts.mason == false`.

## Phase 2: Add Language Declarations

### Create `lang/init.lua`

Use an explicit list for stable registration:

```lua
local languages = {
  'csharp',
  'go',
  'lua',
  'markdown',
  'python',
  'typescript',
}

for _, language in ipairs(languages) do
  require('lang.' .. language)
end
```

### Move language-specific LSP config

- `plugins/050-lsp/020-csharp.lua` -> `lang/csharp.lua`
- `plugins/050-lsp/020-lua.lua` -> `lang/lua.lua`
- `plugins/050-lsp/020-markdown.lua` -> `lang/markdown.lua`
- `plugins/050-lsp/020-python.lua` LSP section -> `lang/python.lua`
- `plugins/050-lsp/020-typescript.lua` -> `lang/typescript.lua`

### Move language-specific DAP config

From current `plugins/090-debug/010-dap.lua`:

- Python/debugpy and `dap-python` dependency -> `lang/python.lua`
- Go/delve and `dap-go` dependency -> `lang/go.lua`
- .NET/netcoredbg configs -> `lang/csharp.lua`
- JS/TS `js-debug-adapter` configs -> `lang/typescript.lua`

Use `mason-nvim-dap.nvim` handlers where automatic setup can cover the adapter, and keep `registry.dap_setup(fn)` hooks only for custom configurations that are not covered by handler overrides.

### Move lint config

- `python = { 'ruff' }` -> `lang/python.lua`
- `markdown = { 'markdownlint' }` -> `lang/markdown.lua`

### Move formatting config

- Lua `stylua` tool and format-on-save -> `lang/lua.lua`
- Python `ruff_format` and format-on-save -> `lang/python.lua`
- C# format-on-save -> `lang/csharp.lua`

Use explicit Mason override where formatter name differs from package name:

```lua
registry.formatter('python', 'ruff_format', { mason = 'ruff' })
```

### Move Treesitter parser declarations

Language-owned parsers:

- C#: `c_sharp`
- Go: `go`
- Lua: `lua`, `luadoc`
- Markdown: `markdown`, `markdown_inline`
- Python: `python`
- TypeScript/JavaScript: `javascript`, `typescript`, `tsx`

Keep baseline parsers in the Treesitter plugin spec:

- `bash`
- `c`
- `diff`
- `html`
- `query`
- `vim`
- `vimdoc`

### Move Neotest adapter declarations

- Python markers/adapter/dependency -> `lang/python.lua`
- Go markers/adapter/dependency -> `lang/go.lua`
- C# VSTest markers/adapter/dependency -> `lang/csharp.lua`
- Jest/Vitest/Bun/Deno markers/adapters/dependencies -> `lang/typescript.lua`

Keep shared helper functions for marker/root detection in `plugins/diagnostics/neotest.lua` unless they become reusable enough to move into a support module later.

## Phase 3: Update Plugin Collector

Update `plugins/init.lua`:

- Require `lang` before collecting specs.
- Collect only files under `dot_config/nvim/lua/plugins`.
- Remove numeric priority sorting.
- Sort paths alphabetically only for deterministic spec collection.
- Continue excluding `init.lua`.
- Keep `add_spec()` recursive so files may return a single spec or a list of specs.

Target flow:

```lua
require('lang')

local files = {}
collect(vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'plugins'), files)
table.sort(files)

local specs = {}
for _, path in ipairs(files) do
  add_spec(require(module_name(path)))
end

require('zpack').setup {
  defaults = { confirm = false },
  spec = specs,
}
```

## Phase 4: Move And Rename Plugin Specs

Move current plugin files to their new parent-owned locations.

```text
010-ui/010-guess-indent.lua                   -> ui/guess-indent.lua
010-ui/010-plenary.lua                        -> delete; use repo.spec('plenary') dependencies
010-ui/020-icons.lua                          -> ui/icons.lua
010-ui/025-snacks.lua                         -> ui/snacks.lua
010-ui/030-which-key.lua                      -> ui/which-key.lua
010-ui/040-colorscheme.lua                    -> ui/colorscheme.lua
010-ui/050-todo-comments.lua                  -> diagnostics/todo-comments.lua
010-ui/060-mini.lua                           -> ui/mini.lua
010-ui/070-indent-line.lua                    -> ui/indent-line.lua
010-ui/080-smooth-cursor.lua                  -> ui/smear-cursor.lua
010-ui/090-bufferline.lua                     -> ui/bufferline.lua

020-git/010-gitsigns.lua                      -> git/gitsigns.lua
020-git/020-lazygit.lua                       -> git/lazygit.lua

030-editing/010-autopairs.lua                 -> editing/autopairs.lua
030-editing/020-auto-reload.lua               -> editing/auto-reload.lua
030-editing/030-undotree.lua                  -> editing/undotree.lua
030-editing/040-gotmpl.lua                    -> editing/gotmpl.lua

040-navigation/010-telescope.lua              -> navigation/telescope.lua
040-navigation/020-neo-tree.lua               -> navigation/neo-tree.lua
040-navigation/030-harpoon.lua                -> navigation/harpoon.lua

050-lsp/010-lsp.lua                           -> lsp/lsp.lua
050-lsp/030-lspeek.lua                        -> lsp/lspeek.lua
050-lsp/020-*.lua                             -> lang/*.lua declarations

060-formatting/010-conform.lua                -> formatting/conform.lua

070-completion/010-luasnip.lua                -> completion/luasnip.lua
070-completion/020-blink.lua                  -> completion/blink.lua

080-diagnostics/010-lint.lua                  -> diagnostics/lint.lua
080-diagnostics/020-trouble.lua               -> diagnostics/trouble.lua
080-diagnostics/030-workspace-diagnostics.lua -> diagnostics/workspace-diagnostics.lua
080-diagnostics/040-tiny-inline-diagnostic.lua -> diagnostics/tiny-inline-diagnostic.lua

090-debug/010-dap.lua                         -> dap/dap.lua
090-debug/020-overseer.lua                    -> dap/overseer.lua
090-debug/030-neotest.lua                     -> diagnostics/neotest.lua

100-integrations/010-opencode.lua             -> integrations/opencode.lua

110-treesitter/010-treesitter.lua             -> ui/treesitter.lua
```

After moving, delete empty numeric directories.

## Phase 5: Convert Specs To `tooling.repos`

Each plugin spec should use `repo.spec(key, overrides)`.

Example:

```lua
local repo = require('tooling.repos')

return repo.spec('lsp_peek', {
  keys = {
    { 'grpd', function() require('lspeek').peek_definition() end, desc = '[G]oto [R] Peek [D]efinition' },
    { 'grpt', function() require('lspeek').peek_type_definition() end, desc = '[G]oto [R] Peek [T]ype Definition' },
  },
  opts = {
    window = { border = 'rounded' },
  },
})
```

Replace direct `util.github` usage in plugin specs with repo keys.

Keep `util.github` only if still useful elsewhere; otherwise remove it after confirming no references remain.

## Phase 6: Mason Spec

Create `plugins/mason.lua` as the single installer owner.

Responsibilities:

- Setup Mason.
- Setup `mason-tool-installer.nvim` with `registry.mason.tools`.
- Run on start with no delay.
- Block until tools are installed, fail, or timeout.
- Warn on failures/timeouts, then proceed.

Use `mason-tool-installer.nvim` to manage installation, and use Mason registry state only for waiting/checking.

Sketch:

```lua
local repo = require('tooling.repos')
local registry = require('tooling.registry')

return repo.spec('mason', {
  dependencies = {
    repo.spec('mason_tool_installer'),
  },
  config = function()
    require('mason').setup({})

    require('mason-tool-installer').setup({
      ensure_installed = registry.mason.tools,
      run_on_start = true,
      start_delay = 0,
    })

    -- Wait for registry.mason.tools to be installed or fail.
    -- Timeout and warn rather than aborting startup.
  end,
})
```

Consumers that require external tools should depend on `repo.spec('mason')`.

## Phase 7: LSP Spec

`plugins/lsp/lsp.lua` should:

- Depend on Mason.
- Depend on `fidget.nvim` as `lsp_status`.
- Enable all servers in `registry.lsp.servers`.
- Not run Mason installation itself.

Sketch:

```lua
local repo = require('tooling.repos')
local registry = require('tooling.registry')

return repo.spec('lsp', {
  dependencies = {
    repo.spec('mason'),
    repo.spec('lsp_status', { opts = {} }),
  },
  config = function()
    for name, server in pairs(registry.lsp.servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
})
```

## Phase 8: DAP Spec

`plugins/dap/dap.lua` should:

- Depend on Mason.
- Depend on `mason-nvim-dap.nvim` as `mason_dap`.
- Depend on DAP UI, NIO, virtual text, plus `registry.dap.dependencies`.
- Run `mason-nvim-dap.setup({ automatic_setup = true, handlers = registry.dap.handlers })`.
- Keep DAP UI/listener/keymap behavior from current config.
- Apply any extra `registry.dap.setup` hooks.

Sketch:

```lua
local repo = require('tooling.repos')
local registry = require('tooling.registry')

local dependencies = vim.list_extend({
  repo.spec('mason'),
  repo.spec('mason_dap'),
  repo.spec('dap_ui'),
  repo.spec('nio'),
  repo.spec('dap_virtual_text'),
}, registry.dap.dependencies)

return repo.spec('dap', {
  dependencies = dependencies,
  keys = {
    -- existing DAP keys
  },
  config = function()
    require('mason-nvim-dap').setup({
      automatic_setup = true,
      handlers = registry.dap.handlers,
    })

    -- existing dapui, virtual text, listeners

    for _, setup in ipairs(registry.dap.setup) do
      setup()
    end
  end,
})
```

## Phase 9: Diagnostics, Formatting, Treesitter, Testing

### `plugins/diagnostics/lint.lua`

- Use `registry.lint.linters_by_ft`.
- Keep current lint autocmd behavior.
- Depend on Mason if lint tools should be installed before lint runs.

### `plugins/formatting/conform.lua`

- Use `registry.formatting.formatters_by_ft`.
- Use `registry.formatting.format_on_save` to decide `format_on_save`.
- Depend on Mason.

### `plugins/ui/treesitter.lua`

- Install baseline parsers plus `registry.treesitter.parsers`.
- Preserve current attach/autoinstall behavior.

### `plugins/diagnostics/neotest.lua`

- Depend on Plenary, NIO, Treesitter, and `registry.testing.dependencies`.
- Build adapters from `registry.testing.adapters`.
- Preserve current keys and guarded root detection behavior.

## Phase 10: Dependency-Only Plenary

- Do not create a standalone `plugins/ui/plenary.lua`.
- Add `plenary` to `tooling/repos.lua`.
- Use `repo.spec('plenary')` in Telescope, Neo-tree, Harpoon, Neotest, or any other dependent plugin.
- Confirm no direct standalone Plenary spec remains.

## Phase 11: Cleanup

- Delete `dot_config/nvim/lua/lsp/registry.lua` after replacing it with `tooling/registry.lua`.
- Delete the empty/unneeded `dot_config/nvim/lua/dap/010-dap.lua` if it is still present and intentionally obsolete.
- Remove numeric plugin directories after all files are moved.
- Update stale comments that reference old numbered paths.
- Remove `util.github` if no references remain.

## Phase 12: Verification

Run checks after each major phase if possible:

```sh
luac -p dot_config/nvim/lua/**/*.lua
nvim --headless '+quitall'
```

If shell globstar is unavailable, use a file listing command appropriate for the shell.

Additional targeted checks:

- Confirm `require('lang')` succeeds headlessly.
- Confirm `require('tooling.registry').mason.tools` includes expected tools.
- Confirm zpack receives specs without numeric folder prefixes.
- Confirm Mason warns and proceeds on install timeout/failure.
- Confirm LSP servers are enabled from `registry.lsp.servers`.
- Confirm DAP runs `mason-nvim-dap.nvim` with `automatic_setup = true`.
- Confirm linting, formatting, Treesitter, and Neotest read registry-backed config.

## Phase 13: Suggested Commit Boundaries

1. Add `tooling.repos`, `tooling.registry`, and `lang` declarations.
2. Update plugin collector and add Mason installer spec.
3. Move/rename plugin folders and convert specs to `tooling.repos`.
4. Move LSP and DAP language config into `lang`.
5. Move linting, formatting, Treesitter, and Neotest language config into `lang`.
6. Remove obsolete files and stale comments.
7. Run final verification and fix any startup issues.
