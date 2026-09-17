local LrPathUtils = import 'LrPathUtils'

local cache = {}

requirePlugin = function(relativePath)
  if cache[relativePath] then
    return cache[relativePath]
  end
  local fullPath = LrPathUtils.child(_PLUGIN.path, relativePath)
  local module = dofile(fullPath)
  cache[relativePath] = module
  return module
end

return requirePlugin
