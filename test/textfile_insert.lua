file.copy"test/textfile_insert_test.txt"{
  dest  = "test/tmp/textfile_insert_test.txt",
  force = "true"
}

textfile.insert_line"test/tmp/textfile_insert_test.txt"{
  line = "HERE",
  diff = "true"
}

