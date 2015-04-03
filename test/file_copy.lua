
file.directory {
  path = "test/tmp/file_copy_src"
}

files = {
  { path = "test/tmp/file_copy_src/one" },
  { path = "test/tmp/file_copy_src/two" },
  { path = "test/tmp/file_copy_src/three" },
}

for f in list(files) do
  file.touch(f)
end

file.copy {
  recurse = "true",
  src     = "test/tmp/file_copy_src",
  dest    = "test/tmp/file_copy_dest"
}
