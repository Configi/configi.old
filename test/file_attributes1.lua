
file.touch {
  path = "test/tmp/file_attributes1"
}

file.attributes {
  path  = "test/tmp/file_attributes1"
  mode  = "0600"
  uid   = "nobody"
  group = "nobody"
}


