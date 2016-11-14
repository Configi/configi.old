file.copy"test/template_insert_test.txt"
    dest: "test/tmp/template_insert_test.txt"
    force: "true"

template.insert_line"test/tmp/template_insert_test.txt"
    line: "HERE"
    diff: "true"
