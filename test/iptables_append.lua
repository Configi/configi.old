iptables.append {
  table    = "filter"
  chain    = "input"
  target   = "accept"
  source   = "6.6.6.6"
  protocol = "tcp"
  options  = "-m tcp --sport 31337 --dport 31337 -m comment --comment 'Configi'"
}
