local grouping = requirePlugin('plugin/core/grouping.lua')
local catalog = requirePlugin('plugin/core/catalog.lua')

local Operation = {}

Operation.id = 'stack_by_name'
Operation.name = 'Stack by base name'
Operation.description = 'Group jpg + raw pairs by base file name and stack them.'

function Operation.identify(entries, options)
  return grouping.identify(entries, options)
end

function Operation.selectGroup(cat, group, options)
  local primary = grouping.choosePrimary(group, options)
  local others = {}
  for _, entry in ipairs(group) do
    if entry.photo ~= primary.photo then
      table.insert(others, entry.photo)
    end
  end
  catalog.selectPhotos(cat, primary.photo, others)
end

function Operation.isComplete(group)
  for _, entry in ipairs(group) do
    if not catalog.isStacked(entry.photo) then
      return false
    end
  end
  return true
end

function Operation.describe(group)
  local names = {}
  for _, entry in ipairs(group) do
    table.insert(names, entry.fileName)
  end
  table.sort(names)
  return table.concat(names, ' + ')
end

return Operation
