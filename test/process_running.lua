shell.command"/bin/touch /tmp/RUNNING"{
    handle = "running"
}
process.running"/usr/bin/login"{
    cmdline = "login -- root",
    context = fact.osfamily.rhel,
    name = "login",
    notify_kept = "running"
}

process.running"/bin/login"{
    cmdline = "/bin/login --",
    context = fact.osfamily.gentoo or fact.osfamily.debian,
    name = "login",
    notify_kept = "running"
}
