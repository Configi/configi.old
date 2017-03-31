file.copy"test/edit_insert_test.txt"{
  dest  = "test/tmp/edit_insert_test.txt",
  force = "true"
}

edit.insert_line"test/tmp/edit_insert_test.txt"{
  line = "HERE",
  diff = "true"
}

