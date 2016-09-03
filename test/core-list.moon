
d = {
    ["test/tmp/core-list.xxx"]: { comment: "s" }
    ["test/tmp/core-list.yyy"]: { comment: "x" }
}

for str, tbl in list(d)
    file.absent(str)(tbl)

