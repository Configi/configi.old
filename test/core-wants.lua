file.touch"test/tmp/core-wants-nodeps"{
    comment = "nodeps"
}
file.absent"test/tmp/core-wants-nodeps"{
    comment = "delete-nodeps"
}
file.absent"test/tmp/core-wants"{
    comment = "2nd",
    wants = [[file.touch"test/tmp/core-wants-nodeps"]]
}
file.touch"test/tmp/core-wants"{
    comment = "4th",
    wants = [[file.touch"test/tmp/core-wants-first"]]
}
file.touch"test/tmp/core-wants-first"{
    comment = "3rd",
    wants = [[file.absent"FIRST"]]
}
file.absent"FIRST"{
    comment = "1st"
}
file.touch"test/tmp/core-wants-last"{
    comment = "last"
}
file.absent"test/tmp/core-wants-last"{
    comment = "delete-last"
}
