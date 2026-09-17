---
name: lrc-sdk
description: Use when writing or editing Lightroom Classic plugin code in this repo — Info.lua manifest, any .lua under CustomLRStacking.lrdevplugin/ (LrCatalog/LrPhoto API, LrView/LrDialogs UI, LrBinding data binding, LrTasks, LrPrefs), the operation registry in plugin/operations/, or the tests. Covers the Lua 5.1 sandbox limits (no require, restricted globals) and the stacking API limitation.
---

# Lightroom Classic SDK — project reference

Verified against the Lightroom Classic SDK (LuaDoc, lrc.mcor.dev) and community
references. Use this instead of guessing — the SDK differs from browser JS and from
older ExtendScript-era docs in ways that cost hours.

## Runtime model

- **Lightroom Classic only** (cloud Lightroom has no plugin SDK). Plugin = Lua **5.1.5**
  scripts in a `.lrdevplugin` (dev) / `.lrplugin` (release) folder.
- **Sandbox:** no `require`, no `package`, no `module`, no `getfenv`/`setfenv`, no
  `collectgarbage`. Use `import 'LrXyz'` for SDK namespaces and `dofile` for plugin files.
- `Info.lua` runs in an even more restricted env (only `string`, `LOC()`,
  `WIN_ENV`/`MAC_ENV`, `_VERSION`) — no `import` there.
- Load plugin modules via the repo's `requirePlugin(path)` global (set by
  `plugin/core/loader.lua`); it caches on `dofile`.

## Manifest (Info.lua)

Required: `LrSdkVersion`, `LrToolkitIdentifier` (reverse-domain string), `LrPluginName`.
Menus: `LrLibraryMenuItems = { { title = "...", file = "relative/path.lua" } }`.
`VERSION = { major, minor, revision }`. This repo targets `LrSdkVersion = 15.0`,
`LrSdkMinimumVersion = 6.0`.

## Stacking limitation (central to this project)

The SDK can create stacks **only at import time** via
`catalog:addPhoto(path, stackWithPhoto, 'above'|'below')`. There is no API to stack
photos already in the catalog. This project therefore **selects** a group and lets the
user stack with the native `Ctrl+G` (top of stack = the primary/most-selected photo).

Key read-only photo facts (all are `getRawMetadata` keys AND `LrPhoto` properties):
`isInStackInFolder`, `stackInFolderMembers`, `topOfStackInFolderContainingPhoto`,
`stackPositionInFolder`, `countStackInFolderMembers`.

## Catalog & photo APIs used here

- `catalog:getActiveSources()` → folders/collections; each has `:getPhotos()`.
- `catalog:getTargetPhotos()` → selection, else whole filmstrip.
- `catalog:setSelectedPhotos(activePhoto, otherSelectedPhotos)` → `activePhoto` = primary.
- `catalog:batchGetRawMetadata(photos, {'path'})` / `batchGetFormattedMetadata(photos, {'fileName'})`
  → tables keyed by photo. Must be called in a task.
- Metadata keys: `fileName` is **getFormattedMetadata**, NOT getRawMetadata. `path` is the
  folder path (getRawMetadata). `fileFormat` = 'RAW'|'DNG'|'JPG'|... `uuid` is persistent.

## UI (floating dialog)

```lua
LrDialogs.presentFloatingDialog(_PLUGIN, {   -- first arg is _PLUGIN (SDK 5.0+)
  title = "...", contents = view,
  onShow = function(c) c.close() end,          -- c.toFront(), c.close()
  windowWillClose = function() end,            -- fires when the dialog closes
})
```

- `LrView.osFactory()` → `f:column{...}`, `f:row{...}`, `f:static_text{title=...}`,
  `f:push_button{title=..., action=function()end}`.
- Binding: `props = LrBinding.makePropertyTable(context)` (context from
  `LrFunctionContext.callWithContext(name, fn)`), then `f:static_text { title = LrView.bind('key') }`
  and set `props.key = value` to update.
- Run long work in `LrTasks.startAsyncTask(...)`; poll with `LrTasks.sleep(seconds)`.
- Present dialogs on the main thread; do catalog queries inside tasks.

## Pitfalls

- Don't call modal dialogs (`LrDialogs.message`, `presentModalDialog`) from inside a task.
- `LrPrefs`: only top-level scalar assignment persists; use `prefs:pairs()` not `pairs(prefs)`.
- Long-lived floating dialogs leak: alternate file paths for `f:picture`, guard
  `requestJpegThumbnail` callbacks, debounce tasks, keep module state fixed-size
  (no `collectgarbage` in sandbox).
- `getDevelopSettings` has typo'd keys (`HueAdjustmentMagenha`, `LuminanceAdjustmentAque`,
  `Parametriclights`) — not used here but easy to trip on.
- `setSelectedPhotos`/catalog queries must run in a task; keep `_PLUGIN.path` for file paths.

## Adding an operation

Copy `plugin/operations/_template.lua`; implement `id`, `name`, `description`,
`identify(entries, options) -> groups, singles`, `selectGroup(catalog, group, options)`,
`isComplete(group) -> bool`, `describe(group) -> string`. Then add a
`plugin/commands/*.lua` entry point and register it in `Info.lua`. Core (runner, catalog,
settings, logger) stays operation-agnostic.
