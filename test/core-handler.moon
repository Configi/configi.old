include"core-handler_include.moon"
notify = "touch_file"
file.directory"test/tmp/core-handler-directory"
    debug: "true"
    mode: "0700"
    notify: notify

file.absent"test/tmp/core-handler-directory"
    notify: "delete_file"
