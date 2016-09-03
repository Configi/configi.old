
file.directory"test/tmp/file_copy_src"()

files = {
    ["test/tmp/file_copy_src/one"]: {}
    ["test/tmp/file_copy_src/two"]: {}
    ["test/tmp/file_copy_src/three"]: {}
}

for s, t in list(files)
    file.touch(s)(t)

file.copy"test/tmp/file_copy_src"
    recurse: "true"
    dest: "test/tmp/file_copy_dest"
