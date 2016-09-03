
d = {
  ["test/tmp/core-list.xxx"] = { comment = "s" },
  ["test/tmp/core-list.yyy"] = { comment = "x" }
}

for str, tbl in list(d) do
  file.absent(str)(tbl)
end

