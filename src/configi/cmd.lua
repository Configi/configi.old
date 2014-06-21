local Lc = require"cimicida"
local Px = require"pexec"
local ipairs, concat = ipairs, table.concat
local ev = Px.execv
local cmd = {}
local ENV = {} ; _ENV = ENV

function parse (args)
  local nul = ""
  local argv = {}
  if args.test then
    argv[#argv + 1] = "/bin/echo"
    argv[#argv + 1] = "-n"
  end
  if args.env then
    argv[#argv + 1] = "/usr/bin/env"
    argv[#argv + 1] = args.env
  end
  local argv = {}
  for n, a in ipairs(args[1]) do
    if a == "bin" then
      argv[#argv + 1] = args.bin or args[2][n]
    elseif args[a] then
      argv[#argv + 1] = args[2][n]
      if args[a] ~= true then
        argv[#argv + 1] = args[a]
      end
    end
  end
  return argv
end

function pr (args)
  if args._pipe == true then
    return parse(args)
  elseif args._write == true then
    return Lc.pwrite(concat(parse(args), " "), args._input)
  else
    return Lc.popen(concat(parse(args), " "))
  end
end

function sr (args)
  if args.pipe == true then
    return parse(args)
  end
  return Lc.system(concat(parse(args), " "))
end

function er (args)
  if args.pipe == true then
    return parse(args)
  end
  return Lc.execute(concat(parse(args), " "))
end

function cmd.crontab (a)
  a[1] = {              "bin", "list", "user", "file" }
  a[2] = { "/usr/bin/crontab",   "-l",   "-u",    nil }
  return pr(a)
end

function cmd.printf (a)
  a[1] = {             "bin", "format", "string" }
  a[2] = { "/usr/bin/printf",       "",       "" }
  return pr(a)
end

function cmd.cp (a)
  a[1] = {     "bin", "recurse", "preserve", "followsrc", "source", "target" }
  a[2] = { "/bin/cp",      "-R",       "-p",        "-H",       "",       "" }
  return ev(a)
end

function cmd.chown (a)
  a[1] = {            "bin", "recurse", "nodereference", "owner", "group", "file" }
  a[2] = { "/usr/bin/chown",      "-R",             "-h",      "",     ":",     "" }
  return ev(a)
end

function cmd.chmod (a)
  a[1] = {        "bin", "recurse", "nodereference", "mode", "file" }
  a[2] = { "/bin/chmod",      "-R",             "-h",    "",     "" }
  return ev(a)
end

function cmd.dig (a)
  a[1] = {          "bin",  "short", "server", "qtype", "class", "file", "ipv4", "debug", "reverse", "name" }
  a[2] = { "/usr/bin/dig", "+short",      "@",    "-t",    "-c",   "-f",   "-4",    "-m",      "-x",   "-q" }
  return pr(a)
end

function cmd.find (a)
  a[1] = {           "bin", "dir",   "name",   "iname" }
  a[2] = { "/usr/bin/find",    "", "-name ", "-iname " }
  return pr(a)
end

function cmd.ln (a)
  a[1] = {     "bin", "force", "symlink", "source", "target" }
  a[2] = { "/bin/ln",    "-f",      "-s",       "",       "" }
  return ev(a)
end

function cmd.logger (a)
  a[1] = {             "bin", "pid", "stderr", "file", "prio", "tag", "message" }
  a[2] = { "/usr/bin/logger",  "-i",     "-s",   "-f",   "-p",  "-t",        "" }
  return ev(a)
end

function cmd.mkdir (a)
  a[1] = {        "bin", "mode", "parents", "name" }
  a[2] = { "/bin/mkdir",   "-m",      "-p",     "" }
  return ev(a)
end

function cmd.stat (a)
  a[1] = {           "bin",   "mode", "owner", "group", "file" }
  a[2] = { "/usr/bin/stat", "-f %Lp", "-f %u", "-f %g",     "" }
  return ev(a)
end

function cmd.touch (a)
  a[1] = {            "bin", "file" }
  a[2] = { "/usr/bin/touch",     "" }
  return ev(a)
end

function cmd.msmtmp (a)
  a[1], a[2] = {}, {}
  a[1][ 1] =  "bin"
  a[1][ 2] = "file"
  a[1][ 3] = "account"
  a[1][ 4] = "host"
  a[1][ 5] = "port"
  a[1][ 6] = "timeout"
  a[1][ 7] = "domain"
  a[1][ 8] = "auth"
  a[1][ 9] = "user"
  a[1][10] = "passwordeval"
  a[1][11] = "tls"
  a[1][12] = "tls-starttls"
  a[1][13] = "tls-force-sslv3"
  a[1][14] = "tls-trust-file"
  a[1][15] = "auto-from"
  a[1][16] = "from"
  a[1][17] = "maildomain"
  a[1][18] = "logfile"
  a[1][19] = "syslog"
  a[1][20] = "read-recipients"
  a[1][21] = "read-envelope-from"
  a[1][22] = "aliases"
  a[2][ 1] = "/usr/bin/msmtp"
  a[2][ 2] = "--file="
  a[2][ 3] = "--account="
  a[2][ 4] = "--host="
  a[2][ 5] = "--port="
  a[2][ 6] = "--timeout="
  a[2][ 7] = "--domain="
  a[2][ 8] = "--auth="
  a[2][ 9] = "--user="
  a[2][10] = "--passwordeval="
  a[2][11] = "--tls="
  a[2][12] = "--tls-starttls="
  a[2][13] = "--tls-force-sslv3="
  a[2][14] = "--tls-trust-file="
  a[2][15] = "--auto-from="
  a[2][16] = "--from="
  a[2][17] = "--maildomain="
  a[2][18] = "--logfile="
  a[2][19] = "--syslog="
  a[2][20] = "--read-recipients="
  a[2][21] = "--read-envelope-from="
  a[2][22] = "--aliases="
  return pr(a)
end

function cmd.ps (a)
  a[1] = {     "bin", "all", "full", "long", "format" }
  a[2] = { "/bin/ps",  "-e",   "-f",   "-l",     "-o" }
  return pr(a)
end

function cmd.rmdir (a)
  a[1] = {        "bin", "parents", "name" }
  a[2] = { "/bin/rmdir",      "-p",     "" }
  return ev(a)
end

function cmd.rm (a)
  a[1] = {     "bin", "recurse", "force", "file" }
  a[2] = { "/bin/rm",      "-r",    "-f",     "" }
  return ev(a)
end

function cmd.sed (a)
  a[1] = {          "bin", "inplace", "command", "command-file", "quiet", "file", "out" }
  a[2] = { "/usr/bin/sed",      "-i",      "-e",           "-f",    "-n",     "",   ">" }
  return pr(a)
end

function cmd.sleep (a)
  a[1] = {            "bin", "seconds" }
  a[2] = { "/bin/sleep",        "" }
  return ev(a)
end

function cmd.tar (a)
  a[1] = {          "bin", "create", "verbose", "list", "extract", "gzip", "bzip2", "xz", "file", "files" }
  a[2] = { "/usr/bin/tar",     "-c",      "-v",   "-t",      "-x",   "-z",    "-j", "-J",   "-f",      "" }
  return pr(a)
end

function cmd.uname (a)
  a[1] = {            "bin", "sysname", "nodename", "release", "version", "machine" }
  a[2] = { "/usr/bin/uname",      "-s",       "-n",      "-r",      "-v",      "-m" }
  return pr(a)
end

function cmd.xsltproc (a)
  a[1] = {               "bin", "output", "stylesheet", "xml" }
  a[2] = { "/usr/bin/xsltproc",     "-o",           "",    "" }
  return ev(a)
end

function cmd.ssh (a)
  a[1], a[2] = {}, {}
  k[ 1] =  "bin"
  k[ 2] = "verbose"
  k[ 3] = "ConnectTimeout"
  k[ 4] = "LogLevel"
  k[ 5] = "StrictHostKeyChecking"
  k[ 6] = "SendEnv"
  k[ 7] = "ServerAliveInterval"
  k[ 8] = "IdentityFile"
  k[ 9] = "login"
  k[10] = "hostname"
  k[11] = "command"
  v[ 1] = "/usr/bin/ssh"
  v[ 2] = "-v"
  v[ 3] = "-oConnectTimeout="
  v[ 4] = "-oLoglevel="
  v[ 5] = "-oStrictHostKeyChecking="
  v[ 6] = "-oSendEnv="
  v[ 7] = "-oServerAliveInterval="
  v[ 8] = "-oIdentityFile="
  v[ 9] = "-l"
  v[10] = ""
  v[11] = ""
  return pr(a)
end

function cmd.curl (a)
  a[1], a[2] = {}, {}
  a[1][ 1] = "bin"
  a[1][ 2] = "output"
  a[1][ 3] = "head"
  a[1][ 4] = "silent"
  a[1][ 5] = "location"
  a[1][ 6] = "user-agent"
  a[1][ 7] = "remote-name"
  a[1][ 8] = "insecure"
  a[1][ 9] = "form"
  a[1][10] = "no-buffer"
  a[1][11] = "dump-header"
  a[1][12] = "ipv4"
  a[1][13] = "write"
  a[1][14] = "url"
  a[2][ 1] = "/usr/bin/curl"
  a[2][ 2] = "-o"
  a[2][ 3] = "-I"
  a[2][ 4] = "-s"
  a[2][ 5] = "-L"
  a[2][ 6] = "-A"
  a[2][ 7] = "-O"
  a[2][ 8] = "-k"
  a[2][ 9] = "-F"
  a[2][10] = "-N"
  a[2][11] = "-D"
  a[2][12] = "-4"
  a[2][13] = "-w"
  a[2][14] = ""
  return pr(a)
end

function cmd.emerge (a)
  a[1], a[2] = {}, {}
  a[1][ 1] = "bin"
  a[1][ 2] = "deep"
  a[1][ 3] = "depclean"
  a[1][ 4] = "newuse"
  a[1][ 5] = "nodeps"
  a[1][ 6] = "noreplace"
  a[1][ 7] = "oneshot"
  a[1][ 8] = "onlydeps"
  a[1][ 9] = "quiet"
  a[1][10] = "sync"
  a[1][11] = "update"
  a[1][12] = "verbose"
  a[1][13] = "pretend"
  a[1][14] = "atom"
  a[2][ 1] = "/usr/bin/emerge"
  a[2][ 2] = "--deep"
  a[2][ 3] = "--depclean"
  a[2][ 4] = "--newuse"
  a[2][ 5] = "--nodeps"
  a[2][ 6] = "--noreplace"
  a[2][ 7] = "--oneshot"
  a[2][ 8] = "--onlydeps"
  a[2][ 9] = "--quiet"
  a[2][10] = "--sync"
  a[2][11] = "--update"
  a[2][12] = "--verbose"
  a[2][13] = "--pretend"
  a[2][14] = ""
  return pr(a)
end

return cmd


