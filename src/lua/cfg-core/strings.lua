return {
    version = "Configi 2.0.0",
    short_args = "hvtdsmjVxl:p:g:r:f:e:",
    long_args = {
        {"help", "none", "h"},
        {"debug", "none", "v"},
        {"test", "none", "t"},
        {"dump", "none", "d"},
        {"watch", "none", "w"},
        {"periodic", "none", "p"},
        {"syslog", "none", "s"},
        {"log", "required", "l"},
        {"msg", "none", "m"},
        {"version", "none", "V"},
        {"tag", "required", "g"},
        {"runs", "required", "r"},
        {"file", "required", "f"},
        {"embedded","required", "e"},
        {"exec", "none", "x"},
    },
    help = [[
    cfg [-h] [-V] [-v] [-d] [-t] [-w] [-p N] [-s] [-l FILE] [-m] [-g TAG] [-r N] [-f "POLICY"] [-e "POLICY"]

        Options:
            -h, --help                  This help text.
            -V, --version               Print version.
            -v, --debug                 Turn on debugging messages.
            -d, --dump                  Dump tree.
            -t, --test                  Dry-run mode. All operations are expected to succeed. Turns on debugging.
            -w, --watch                 Watch for inotify IN_MODIFY and IN_ATTRIB events to the main policy file.
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
     EXEC = "EXECUTION: "
}
