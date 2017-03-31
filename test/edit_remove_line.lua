file.copy"test/edit_remove_line_test.txt"{
  dest  = "test/tmp/edit_remove_line_test.txt",
  force = "true"
}

edit.remove_line"test/tmp/edit_remove_line_test.txt"{
  plain   = "true",
  pattern = "father",
  diff    = "true"
}

