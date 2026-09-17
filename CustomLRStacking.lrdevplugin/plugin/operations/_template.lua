-- Operation contract template.
-- Copy this file to add a new operation (e.g. renaming, stack by capture time).
-- An operation must expose: id, name, description, identify, selectGroup, isComplete, describe.
--
--   identify(entries, options)      -> groups, singles
--       entries = list of { photo = LrPhoto, fileName = string, folder = string }
--       groups  = list of lists (each an inner list of entries that belong together)
--       singles = list of entries that do not belong to any group
--
--   selectGroup(catalog, group, options)
--       select the group in the grid, with the preferred photo as primary (top of stack)
--
--   isComplete(group)               -> boolean
--       true when the group no longer needs attention (e.g. already stacked)
--
--   describe(group)                 -> string
--       short human-readable label shown in the progress dialog

local Operation = {}

Operation.id = 'template'
Operation.name = 'Template operation'
Operation.description = 'Describe what this operation does.'

function Operation.identify(entries, options)
  return {}, entries
end

function Operation.selectGroup(catalog, group, options)
end

function Operation.isComplete(group)
  return true
end

function Operation.describe(group)
  return group[1].fileName
end

return Operation
