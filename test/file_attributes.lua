
file.touch"test/tmp/file_attributes1"()
file.touch"test/tmp/file_attributes2"()
file.touch"test/tmp/file_attributes3"()

file.attributes"test/tmp/file_attributes1"{
  mode  = 0600,
  uid   = "nobody",
  group = "nobody"
}

file.attributes"test/tmp/file_attributes2"{
  mode = "0755"
}

file.attributes"test/tmp/file_attributes3"{
  mode = 444
}
