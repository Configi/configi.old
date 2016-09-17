module "fact"
context = fact.interfaces.lo.ipv4['127.0.0.11']

file.touch "test/tmp/core-context"{
  context = context
}
