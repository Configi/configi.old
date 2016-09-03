file.copy"test/textfile_remove_line_test.txt"
    dest: "test/tmp/textfile_remove_line_test.txt"
    force: "true"

textfile.remove_line"test/tmp/textfile_remove_line_test.txt"
    plain: "true"
    pattern: "father"
    diff: "true"
