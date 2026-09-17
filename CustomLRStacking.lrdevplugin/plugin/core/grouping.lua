local Grouping = {}

local DEFAULT_RAW = {
  arw = true, cr2 = true, cr3 = true, nef = true, nrf = true, raf = true, orf = true,
  rw2 = true, pef = true, dng = true, raw = true, srw = true, ['3fr'] = true, sr2 = true,
  rwl = true, dcr = true, mrw = true, erf = true, kdc = true, mef = true, mos = true,
  x3f = true, fff = true, gpr = true,
}

local DEFAULT_JPG = { jpg = true, jpeg = true }

local function lowerExt(fileName)
  local ext = fileName:match('%.([^.]+)$')
  if ext then return ext:lower() end
  return ''
end

local function stemOf(fileName)
  local stem = fileName:match('^(.*)%.[^.]+$') or fileName
  return stem:lower()
end

function Grouping.defaultOptions()
  return {
    top_of_stack = 'raw_first',
    raw_extensions = DEFAULT_RAW,
    jpg_extensions = DEFAULT_JPG,
  }
end

function Grouping.stemOf(fileName)
  return stemOf(fileName)
end

function Grouping.isRaw(entry, options)
  return options.raw_extensions[lowerExt(entry.fileName)] == true
end

function Grouping.isJpg(entry, options)
  return options.jpg_extensions[lowerExt(entry.fileName)] == true
end

function Grouping.qualifies(members, options)
  if #members < 2 then return false end

  local hasRaw = false
  local extensions = {}
  for _, member in ipairs(members) do
    local ext = lowerExt(member.fileName)
    extensions[ext] = true
    if options.raw_extensions[ext] then hasRaw = true end
  end
  if not hasRaw then return false end

  local distinct = 0
  for _ in pairs(extensions) do distinct = distinct + 1 end
  return distinct >= 2
end

function Grouping.identify(entries, options)
  options = options or Grouping.defaultOptions()

  local groupsByKey = {}
  local order = {}
  for _, entry in ipairs(entries) do
    local key = (entry.folder or '') .. '|' .. stemOf(entry.fileName)
    local members = groupsByKey[key]
    if not members then
      members = {}
      groupsByKey[key] = members
      table.insert(order, key)
    end
    table.insert(members, entry)
  end

  local groups = {}
  local singles = {}
  for _, key in ipairs(order) do
    local members = groupsByKey[key]
    if Grouping.qualifies(members, options) then
      table.insert(groups, members)
    else
      for _, member in ipairs(members) do
        table.insert(singles, member)
      end
    end
  end

  table.sort(groups, function(a, b)
    return stemOf(a[1].fileName) < stemOf(b[1].fileName)
  end)

  return groups, singles
end

function Grouping.choosePrimary(members, options)
  local function find(predicate)
    for _, member in ipairs(members) do
      if predicate(member) then return member end
    end
    return nil
  end

  if options.top_of_stack == 'jpg_first' then
    return find(function(member) return Grouping.isJpg(member, options) end) or members[1]
  end
  return find(function(member) return Grouping.isRaw(member, options) end) or members[1]
end

return Grouping
