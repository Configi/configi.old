shell.command"/bin/touch /tmp/NOT-RUNNING"{
    handle = "not-running"
}
process.running"/whatever"{
    notify_failed = "not-running"
}
