file.touch"test/tmp/core-handler-dummy"()
file.absent"test/tmp/core-handler-dummy"()
file.touch"test/tmp/core-handler-file"{
  handle = "touch_file"
}
file.absent"test/tmp/core-handler-file"{
  handle = "delete_file"
}
