context = fact.interfaces.lo.ipv4['127.0.0.11']
file.touch "test/tmp/core-context"{
  context = context
}
file.touch "test/tmp/core-context-true"{
  context = fact.interfaces.lo.ipv4['127.0.0.1']
}
