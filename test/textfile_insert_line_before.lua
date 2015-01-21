
file.copy [[
  src "test/textfile_insert_line_test.txt"
  dest "test/tmp/textfile_insert_line_test.txt"
  force "true"
]]

textfile.insert_line [[
  dest "test/tmp/textfile_insert_line_test.txt"
  plain "true"
  before "true"
  pattern "father"
  line "mother"
  diff "true"
]]

