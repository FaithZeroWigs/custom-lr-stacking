local LrLogger = import 'LrLogger'

local Logger = {}

local log = LrLogger('customLRStacking')
log:enable('logfile')

local levels = { off = 0, error = 1, warn = 2, info = 3, trace = 4 }
local currentLevel = levels.info

function Logger.setLevel(name)
  currentLevel = levels[name] or levels.info
end

function Logger.error(message)
  if currentLevel >= levels.error then log:error(message) end
end

function Logger.warn(message)
  if currentLevel >= levels.warn then log:warn(message) end
end

function Logger.info(message)
  if currentLevel >= levels.info then log:info(message) end
end

function Logger.trace(message)
  if currentLevel >= levels.trace then log:info(message) end
end

return Logger
