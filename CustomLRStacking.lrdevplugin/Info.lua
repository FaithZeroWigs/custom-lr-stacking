return {
  VERSION = { major = 0, minor = 1, revision = 0 },

  LrSdkVersion = 15.0,
  LrSdkMinimumVersion = 6.0,

  LrToolkitIdentifier = 'dev.gabi.customlrstacking',
  LrPluginName = 'Custom LR Stacking',

  LrLibraryMenuItems = {
    { title = 'Stack groups in folder', file = 'plugin/commands/stack_folder.lua' },
    { title = 'Stack groups in selection', file = 'plugin/commands/stack_selection.lua' },
  },
}
