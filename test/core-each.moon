t = {
    ["test/tmp/core-each.xxx"]: { comment: "test" }
    ["test/tmp/core-each.yyy"]: { comment: "test" }
}

each(t, file.absent)
