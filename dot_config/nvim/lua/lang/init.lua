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
