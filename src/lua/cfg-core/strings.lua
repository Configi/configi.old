return {
  version = "Configi 2.0.0",
  short_args = "hvtdsmjFVxl:p:g:r:f:e:",
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
    {"facts", "none", "F"},
    {"version", "none", "V"},
    {"tag", "required", "g"},
    {"runs", "required", "r"},
    {"file", "required", "f"},
    {"embedded","required", "e"},
    {"exec", "none", "x"},
  },
  help = [[
  cfg-agent [-h] [-V] [-d] [-t] [-w] [-p N] [-s] [-m] [-x] [-F] [-v] [-l FILE] [-g TAG] [-r N] [-f POLICY] [-e POLICY]

      Options:
          -h  This help text.
          -V  Print version.
          -d  Dump tree.
          -t  Dry-run mode. All operations are expected to succeed. Turns on full debugging (-v).
          -w  Watch for inotify IN_MODIFY and IN_ATTRIB events to the main policy file.
          -p  Do a run after N seconds.
          -s  Enable logging to syslog.
          -l  Log to an specified FILE.
          -m  Show minimal debug and test messages.
          -x  Show execution debug messages.
          -F  Gather system facts.
          -v  Show full debugging messages.
          -g  Only run specified TAG(s).
          -r  Run the policy N times if a failure is encountered. Default is 3.
          -f  Path to the Configi POLICY.
          -e  Name of the embedded Configi POLICY.

]],
  IDENT = "Configi",
  ERROR = "ERROR: ",
  WARN = "WARNING: ",
  SERR = "POLICY ERROR: ",
  MERR = "MODULE ERROR: ",
  EXEC = "EXECUTION: ",
  rs = string.char(32)
}
