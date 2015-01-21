
shell.command [[
  creates "test/tmp/shell_command.txt"
  cwd "test/tmp"
  string "/bin/touch shell_command.txt"
]]

shell.command [[
  command "/bin/ls"
]]
