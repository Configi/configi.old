
cron.present"test"{
  minute = "25",
  hour = "09",
  job = "/bin/ls"
}

cron.present"cut"{
  minute = "30",
  hour = "11",
  job = "/bin/ls"
}

cron.present"two"{
  minute = "2",
  hour = "4",
  job = "/bin/ls"
}

cron.absent"whoah"{
  job = "/bin/ls"
}


cp = {
  Moe = { minute = "12", hour = "6", job = "/bin/ls" }
}
each(cp, cron.present)

cp = {
  Larry = { minute = "2", hour = "3", job = "/bin/ls" }
}
each(cp, cron.present)

cp = {
  Curly = { minute = "43", hour = "12", job = "/bin/ls" }
}
each(cp, cron.present)

name = "testing"

cron.present(name) {
  minute = "1",
  hour = "6",
  job = "/bin/ls"
}

gang = {
 name = "south"
 minute = "6",
 hour = "7",
 job = "/bin/ls"
}

cron.present(gang.name){
 minute = gang.minute,
 hour = gang.hour,
 job = gang.job,
}


p = {
  job = "/bin/ls"
}

xp = {
  Rec = { minute = "5", hour = "3", job = p.job }
}

for names, jobs in list(xp) do
  cron.present(names)(jobs)
end
