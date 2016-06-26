
file.touch {
  handle = "touch_file"
  path   = "test/tmp/core-handler-file"
}

file.absent {
  handle = "delete_file"
  path   = "test/tmp/core-handler-file"
}




