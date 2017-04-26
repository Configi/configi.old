module "fact"

file.touch"test/tmp/i-deadbeef"{
    context = fact.aws_instance_id["i-deadbeef"],
    comment = "Test qhttp get to meta-data endpoint."
}
if fact.uptime.totalseconds.number > 0 then
  shell.command"/bin/echo"()
end
