
file.copy"test/edit_insert_line_test.txt" {
  dest   = "test/tmp/edit_insert_line_test.txt",
  force  = "true",
  backup = "true"
}

edit.insert_line"test/tmp/edit_insert_line_test.txt"{
  plain   = "true",
  pattern = "father",
  line    = "mother",
  diff    = "true"
}
