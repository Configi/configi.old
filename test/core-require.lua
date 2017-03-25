file.absent"test/tmp/core-require"{
    comment = "4th",
    before = [[file.touch"test/tmp/core-require-nodeps"]]
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
    comment = "1st"
}
file.touch"test/tmp/core-require-last"{
    comment = "last"
}
file.absent"test/tmp/core-require-last"{
    comment = "delete-last"
}
file.touch"test/tmp/core-require-nodeps"{
    before = [[file.touch"/test/tmp/core-requires-last"]],
    comment = "nodeps"
}
file.absent"test/tmp/core-require-nodeps"{
    comment = "delete-nodeps"
}

