
file.copy"test/template_insert_line_test.txt" {
  dest   = "test/tmp/template_insert_line_test.txt",
  force  = "true",
  backup = "true"
}

template.insert_line"test/tmp/template_insert_line_test.txt"{
  plain   = "true",
  pattern = "father",
  line    = "mother",
  diff    = "true"
}
