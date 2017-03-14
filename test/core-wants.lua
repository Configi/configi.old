file.touch"test/tmp/core-wants-nodeps"{
    comment = "nodeps"
}
file.absent"test/tmp/core-wants-nodeps"{
    comment = "delete-nodeps"
}
file.absent"test/tmp/core-wants"{
    comment = "4th",
    wants = "TOUCH"
}
file.touch"test/tmp/core-wants"{
    comment = "3rd",
    handle = "TOUCH",
    wants = "SECOND"
}
file.touch"test/tmp/core-wants-first"{
    comment = "2nd",
    handle = "SECOND",
    wants = "FIRST"
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
