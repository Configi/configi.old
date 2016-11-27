file.absent"test/tmp/core-wants"{
    comment = "3rd",
    wants = "TOUCH"
}
file.touch"test/tmp/core-wants"{
    comment = "2nd",
    handle = "TOUCH",
    wants = "FIRST"
}
file.touch"test/tmp/core-wants-first"{
    comment = "1st",
    handle = "FIRST"
}
