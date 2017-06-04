file.directory"/configi-test-mount"()
edit.insert_line"/etc/fstab"{
    line = "tmpfs /configi-test-mount tmpfs defaults 0 0"
}
mount.mounted"/configi-test-mount"{
    comment = "mounted"
}
