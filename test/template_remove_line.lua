file.copy"test/template_remove_line_test.txt"{
  dest  = "test/tmp/template_remove_line_test.txt",
  force = "true"
}

template.remove_line"test/tmp/template_remove_line_test.txt"{
  plain   = "true",
  pattern = "father",
  diff    = "true"
}

