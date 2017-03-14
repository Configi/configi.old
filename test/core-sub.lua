VERSION="1.0"
file.touch(sub"test/tmp/FILE-{{VERSION}}"){
    comment = "Test string interpolation with sub()"
}
