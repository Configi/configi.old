
d = {
  { comment = "s", path ="test/tmp/core-list.xxx" },
  { comment = "x", path ="test/tmp/core-list.yyy" }
}

for dirs in list(d) do
  file.absent(dirs)
end

