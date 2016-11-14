
file.copy"test/textfile_insert_line_test.txt" {
  dest   = "test/tmp/textfile_insert_line_test.txt",
  force  = "true",
  backup = "true"
}

textfile.insert_line"test/tmp/textfile_insert_line_test.txt"{
  plain   = "true",
  pattern = "father",
  line    = "mother",
  diff    = "true"
}
