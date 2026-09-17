local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'

local Catalog = requirePlugin('plugin/core/catalog.lua')
local Settings = requirePlugin('plugin/core/settings.lua')
local Logger = requirePlugin('plugin/core/logger.lua')

local Runner = {}

function Runner.run(gather, operation)
  LrFunctionContext.callWithContext('customLRStacking', function(context)
    local props = LrBinding.makePropertyTable(context)
    local control = { skip = false, stop = false, userStopped = false }
    local closeDialog = nil

    props.progress = 'Analyzing photos...'

    local f = LrView.osFactory()
    local contents = f:column {
      bind_to_object = props,
      f:static_text { title = 'Press Ctrl+G to stack the selected group.' },
      f:static_text { title = LrView.bind('progress') },
      f:row {
        f:push_button {
          title = 'Skip',
          action = function() control.skip = true end,
        },
        f:push_button {
          title = 'Stop',
          action = function()
            control.stop = true
            control.userStopped = true
          end,
        },
      },
    }

    LrDialogs.presentFloatingDialog(_PLUGIN, {
      title = 'Custom LR Stacking',
      contents = contents,
      onShow = function(dialogControls)
        closeDialog = dialogControls.close
      end,
      windowWillClose = function()
        control.stop = true
      end,
    })

    LrTasks.startAsyncTask(function()
      local catalog = Catalog.activeCatalog()
      local photos = gather(catalog)

      if not photos or #photos == 0 then
        props.progress = 'No photos found in the current source.'
        Logger.warn('No photos found')
        LrTasks.sleep(2)
        if closeDialog then closeDialog() end
        return
      end

      local options = Settings.options()
      local entries = Catalog.makeEntries(catalog, photos)
      local groups, singles = operation.identify(entries, options)

      Logger.info(string.format('Photos: %d, groups: %d, singles: %d', #photos, #groups, #singles))

      if #groups == 0 then
        props.progress = string.format('No matching groups found (%d single photo(s) skipped).', #singles)
        LrTasks.sleep(2)
        if closeDialog then closeDialog() end
        return
      end

      local stacked = 0
      local skipped = 0
      local alreadyStacked = 0

      for i, group in ipairs(groups) do
        if control.stop then break end

        if options.skip_already_stacked and operation.isComplete(group) then
          alreadyStacked = alreadyStacked + 1
        else
          operation.selectGroup(catalog, group, options)
          props.progress = string.format('Group %d of %d — %s', i, #groups, operation.describe(group))

          while not control.stop and not control.skip do
            if operation.isComplete(group) then break end
            LrTasks.sleep(0.4)
          end

          if control.stop then
            break
          elseif control.skip then
            control.skip = false
            skipped = skipped + 1
          else
            stacked = stacked + 1
          end
        end
      end

      local summary
      if control.userStopped then
        summary = string.format('Stopped. Stacked: %d, Skipped: %d, Already stacked: %d, Singles: %d.',
          stacked, skipped, alreadyStacked, #singles)
      else
        summary = string.format('Done. Stacked: %d, Skipped: %d, Already stacked: %d, Singles: %d.',
          stacked, skipped, alreadyStacked, #singles)
      end

      props.progress = summary
      Logger.info(summary)
      LrTasks.sleep(2)
      if closeDialog then closeDialog() end
    end)
  end)
end

return Runner
