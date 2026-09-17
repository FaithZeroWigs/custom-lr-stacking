local LrPrefs = import 'LrPrefs'

local Settings = {}

local prefs = LrPrefs.prefsForPlugin()

local DEFAULTS = {
  top_of_stack = 'raw_first',
  raw_extensions = 'arw,cr2,cr3,nef,nrf,raf,orf,rw2,pef,dng,raw,srw,3fr,sr2,rwl,dcr,mrw,erf,kdc,mef,mos,x3f,fff,gpr',
  jpg_extensions = 'jpg,jpeg',
  skip_already_stacked = true,
  log_level = 'info',
}

function Settings.get(key)
  local value = prefs[key]
  if value == nil then
    return DEFAULTS[key]
  end
  return value
end

function Settings.set(key, value)
  prefs[key] = value
end

function Settings.getExtensionSet(key)
  local result = {}
  local list = Settings.get(key)
  if list then
    for ext in string.gmatch(list, '([^,]+)') do
      result[ext:lower()] = true
    end
  end
  return result
end

function Settings.options()
  return {
    top_of_stack = Settings.get('top_of_stack'),
    raw_extensions = Settings.getExtensionSet('raw_extensions'),
    jpg_extensions = Settings.getExtensionSet('jpg_extensions'),
    skip_already_stacked = Settings.get('skip_already_stacked'),
  }
end

return Settings
