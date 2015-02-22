t = {
  { path = "test/tmp/core-map.xxx", comment = "test" },
  { path = "test/tmp/core-map.yyy", comment = "test" }
}

map(file.absent, t)

