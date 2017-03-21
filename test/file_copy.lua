
file.directory"test/tmp/file_copy_src"()

files = {
  ["test/tmp/file_copy_src/one"] = {},
  ["test/tmp/file_copy_src/two"] = {},
  ["test/tmp/file_copy_src/three"] = {},
}

for s, t in pairs(files) do
  file.touch(s)(t)
end

file.copy"test/tmp/file_copy_src" {
  recurse = "true",
  dest    = "test/tmp/file_copy_dest"
}
