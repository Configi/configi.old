shell.command"/bin/touch shell_command.txt"
    creates: "test/tmp/shell_command.txt"
    cwd: "test/tmp"

shell.command"/bin/ls"()
