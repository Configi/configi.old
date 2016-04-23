
unarchive.unpack {
  src  = "test/make_install.tar"
  dest = "test/tmp"
}

make.install {
  directory = "test/tmp/make_install"
}
