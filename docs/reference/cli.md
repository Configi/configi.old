#### Options of the cfg executable

```
  cfg [-h] [-V] [-v] [-t] [-D] [-p N] [-s] [-l FILE] [-m] [-g TAG] [-r N] -f "CONFIGI POLICY"

    Options:
      -h, --help          This help text.
      -V, --version       Print version.
      -v, --debug         Turn on debugging messages.
      -t, --test          Dry-run mode. All operations are expected to succeed. Turns on debugging.
      -D, --daemon        Daemon mode. Watch for IN_MODIFY and IN_ATTRIB events to the policy file.
      -p, --periodic      Do a run after N seconds.
      -s, --syslog        Enable logging to syslog.
      -l, --log           Log to an specified file.
      -m, --msg           Show debug and test messages.
      -g, --tag           Only run specified tag(s).
      -r, --runs          Run the policy N times if a failure is encountered. Default is 3.
      -f, --file          Path to the Configi policy.
```
