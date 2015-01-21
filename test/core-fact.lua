debug "true"
module "fact"

if fact.uptime.totalseconds.number > 0 then
  shell.command[[ command "/bin/echo" ]]
end
