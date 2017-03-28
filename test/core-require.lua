file.absent"test/tmp/core-require"{
    comment = "4th",
    before = [[file.touch"test/tmp/core-require-nodeps"]],
    require = [[file.absent"FIRST"]],
    require = [[file.touch"test/tmp/core-require"]]
}
file.touch"test/tmp/core-require"{
    comment = "3rd",
    require = [[file.touch"test/tmp/core-require-first"]],
    before = [[file.touch"test/tmp/core-require-nodeps"]]
}
file.touch"test/tmp/core-require-first"{
    comment = "2nd",
    require = [[file.absent"FIRST"]]
}
file.absent"FIRST"{
    before = [[file.absent"test/tmp/core-require-nodeps"]],
    comment = "1st"
}
file.touch"test/tmp/core-require-last"{
    require = [[file.absent"test/tmp/core-require-nodeps"]],
    before = [[file.absent"test/tmp/core-require-last"]],
    comment = "last"
}
file.absent"test/tmp/core-require-last"{
    require = [[file.absent"test/tmp/core-require-nodeps"]],
    comment = "delete-last"
}
file.touch"test/tmp/core-require-nodeps"{
    before = [[file.touch"/test/tmp/core-require-last"]],
    before = [[file.absent"test/tmp/core-require-nodeps"]],
    comment = "nodeps"
}
file.absent"test/tmp/core-require-nodeps"{
    comment = "delete-nodeps"
}

