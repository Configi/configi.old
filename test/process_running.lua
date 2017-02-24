shell.command"/bin/touch /tmp/RUNNING"{
    handle = "running"
}
process.running"/usr/bin/login"{
    cmdline = "login -- root",
    name = "login",
    notify_kept = "running"
}
