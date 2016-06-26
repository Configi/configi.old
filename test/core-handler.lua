include "core-handler_include.lua"
notify = "touch_file"
file.directory {
  debug  = "true"
  path   = "test/tmp/core-handler-directory"
  mode   = "0700"
  notify = notify
}

file.absent {
  path   = "test/tmp/core-handler-directory"
  notify = "delete_file"
}






