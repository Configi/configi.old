
dirlist = {
  ["test/tmp/CONFIGI_TEST_INCLUDE"] = { comment = "useless" }
}

for k, v in pairs(dirlist) do
  file.absent(k)(v)
end


