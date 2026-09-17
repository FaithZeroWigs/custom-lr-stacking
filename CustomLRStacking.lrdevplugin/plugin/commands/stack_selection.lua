local LrPathUtils = import 'LrPathUtils'

dofile(LrPathUtils.child(_PLUGIN.path, 'plugin/core/loader.lua'))

local settings = requirePlugin('plugin/core/settings.lua')
local logger = requirePlugin('plugin/core/logger.lua')
local catalog = requirePlugin('plugin/core/catalog.lua')
local runner = requirePlugin('plugin/core/runner.lua')
local operation = requirePlugin('plugin/operations/stack_by_name.lua')

logger.setLevel(settings.get('log_level'))

runner.run(catalog.getSelectedPhotos, operation)
