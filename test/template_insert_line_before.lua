file.copy"test/template_insert_line_test.txt"{
  dest  = "test/tmp/template_insert_line_test.txt",
  force = "true"
}

template.insert_line"test/tmp/template_insert_line_test.txt"{
  plain   = "true",
  before_pattern = "true",
  pattern = "father",
  line    = "mother",
  diff    = "true"
}
