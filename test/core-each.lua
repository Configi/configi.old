t = {
  { path = "test/tmp/core-each.xxx", comment = "test" },
  { path = "test/tmp/core-each.yyy", comment = "test" }
}

each(t, file.absent)

