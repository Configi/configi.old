
file.copy {
  src   = "test/textfile_remove_line_test.txt"
  dest  = "test/tmp/textfile_remove_line_test.txt"
  force = "true"
}

textfile.remove_line {
  dest    = "test/tmp/textfile_remove_line_test.txt"
  plain   = "true"
  pattern = "father"
  diff    = "true"
}

