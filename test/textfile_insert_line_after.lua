
file.copy {
  src    = "test/textfile_insert_line_test.txt",
  dest   = "test/tmp/textfile_insert_line_test.txt",
  force  = "true",
  backup = "true"
}

textfile.insert_line {
  dest    = "test/tmp/textfile_insert_line_test.txt",
  plain   = "true",
  pattern = "father",
  line    = "mother",
  diff    = "true"
}
