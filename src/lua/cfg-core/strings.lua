return {
    short_args = "hvtDsmjVl:p:g:r:f:e:",
    long_args = {
        {"help", "none", "h"},
        {"debug", "none", "v"},
        {"test", "none", "t"},
        {"daemon", "none", "D"},
        {"periodic", "none", "p"},
        {"syslog", "none", "s"},
        {"log", "required", "l"},
        {"msg", "none", "m"},
        {"version", "none", "V"},
        {"tag", "required", "g"},
        {"runs", "required", "r"},
        {"file", "required", "f"},
        {"embedded","required", "e"}
    },
    help = [[
    cfg [-h] [-V] [-v] [-t] [-D] [-p N] [-s] [-l FILE] [-m] [-g TAG] [-r N] [-f "CONFIGI POLICY"] [-e "CONFIGI POLICY"]

        Options:
            -h, --help                  This help text.
            -V, --version               Print version.
            -v, --debug                 Turn on debugging messages.
            -t, --test                  Dry-run mode. All operations are expected to succeed. Turns on debugging.
            -D, --daemon                Daemon mode. Watch for IN_MODIFY and IN_ATTRIB events to the policy file.
            -p, --periodic              Do a run after N seconds.
            -s, --syslog                Enable logging to syslog.
            -l, --log                   Log to an specified file.
            -m, --msg                   Show debug and test messages.
            -g, --tag                   Only run specified tag(s).
            -r, --runs                  Run the policy N times if a failure is encountered. Default is 3.
            -f, --file                  Path to the Configi policy.
            -e, --embedded              Name of the embedded Configi policy.

]],
    IDENT = "Configi",
    ERROR = "ERROR: ",
    WARN = "WARNING: ",
    SERR = "POLICY ERROR: ",
    MERR = "MODULE ERROR: ",
    OPERATION = "Operation"
}
