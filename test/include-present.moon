
dirlist = {
  ["test/tmp/CONFIGI_TEST_INCLUDE"]: { comment: "useless" }
}

for s, t in list(dirlist)
  file.directory(s)(t)


