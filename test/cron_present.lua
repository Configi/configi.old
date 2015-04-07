
cron.present {
  name = "test"
  minute = "25"
  hour = "09"
  job = "/bin/ls"
}

cron.present {
  name = "cut"
  minute = "30"
  hour = "11"
  job = "/bin/ls"
}

cron.present {
  name = "two"
  minute = "2"
  hour = "4"
  job = "/bin/ls"
}

cron.absent {
  name = "whoah"
  job = "/bin/ls"
}


cp = {
  { name = "Moe", minute = "12", hour = "6", job = "/bin/ls" },
  { name = "Larry", minute = "2", hour = "3", job = "/bin/ls" },
  { name = "Curly", minute = "43", hour = "12", job = "/bin/ls" }
}

for jobs in list(cp) do
  cron.present(jobs)
end

name = "testing"

cron.present {
  name = name
  minute = "1"
  hour = "6"
  job = "/bin/ls"
}

gang = {
 name = "south"
 minute = "6"
 hour = "7"
 job = "/bin/ls"
}

cron.present {
 name = gang.name
 minute = gang.minute
 hour = gang.hour
 job = gang.job
}


p = {
  job = "/bin/ls"
}

xp = {
  { name = "Rec", minute = "5", hour = "3", job = p.job }
}

for jobs in list(xp) do
  cron.present(jobs)
end
