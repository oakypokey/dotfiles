---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in plugin specs.
---@param repo string
---@return string
return function(repo) return 'https://github.com/' .. repo end
