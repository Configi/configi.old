
dirlist = {
  ["test/tmp/CONFIGI_TEST_INCLUDE"] = { comment = "useless" }
}

for s, t in pairs(dirlist) do
  file.directory(s)(t)
end


