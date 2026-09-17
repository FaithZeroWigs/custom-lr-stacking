local LrApplication = import 'LrApplication'

local Catalog = {}

function Catalog.activeCatalog()
  return LrApplication.activeCatalog()
end

function Catalog.getActiveSourcePhotos(catalog)
  local photos = {}
  local seen = {}
  local sources = catalog:getActiveSources()
  if sources then
    for _, source in ipairs(sources) do
      local sourcePhotos = source:getPhotos()
      if sourcePhotos then
        for _, photo in ipairs(sourcePhotos) do
          if not seen[photo] then
            seen[photo] = true
            table.insert(photos, photo)
          end
        end
      end
    end
  end
  return photos
end

function Catalog.getSelectedPhotos(catalog)
  return catalog:getTargetPhotos()
end

function Catalog.makeEntries(catalog, photos)
  local rawData = catalog:batchGetRawMetadata(photos, { 'path' })
  local fmtData = catalog:batchGetFormattedMetadata(photos, { 'fileName' })
  local entries = {}
  for _, photo in ipairs(photos) do
    table.insert(entries, {
      photo = photo,
      fileName = fmtData[photo].fileName,
      folder = rawData[photo].path,
    })
  end
  return entries
end

function Catalog.selectPhotos(catalog, primary, others)
  catalog:setSelectedPhotos(primary, others)
end

function Catalog.isStacked(photo)
  return photo:getRawMetadata('isInStackInFolder') == true
end

return Catalog
