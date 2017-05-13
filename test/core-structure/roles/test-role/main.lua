file.copy"core-structure-role-copy"{
    comment = "copy from role",
       dest = "test/tmp/core-structure-role-copy"
}
file.copy"core-structure-override-role-copy"{
    comment = "override copy",
       dest = "test/tmp/core-structure-override-role-copy"
}
template.render"test/tmp/core-structure-role-template"{
    comment = "template from role",
        src = "core-structure-role-template",
       view = view_model
}
template.render"test/tmp/core-structure-override-role-template"{
    comment = "override template",
        src = "core-structure-override-role-template",
       view = view_model
}
