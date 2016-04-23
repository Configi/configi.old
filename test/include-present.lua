
dirlist = {
  { comment = "useless", path ="test/tmp/CONFIGI_TEST_INCLUDE"}
}

for dirs in list(dirlist) do
  file.directory(dirs)
end


