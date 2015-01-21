
file.copy [[
  src "test/textfile_insert_test.txt"
  dest "test/tmp/textfile_insert_test.txt"
  force "true"
]]

textfile.insert_line [[
  dest "test/tmp/textfile_insert_test.txt"
  line "HERE"
  diff "true"
]]

