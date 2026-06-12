local registry = require 'tooling.registry'

registry.linter('markdown', 'markdownlint')
registry.treesitter { 'markdown', 'markdown_inline' }
