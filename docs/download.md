# Linux Distribution support
Tested on Gentoo, OpenWRT, Centos 7 and Alpine Linux.

Runs fine on OpenWRT mipsel and mips targets with little as 32MB RAM. Here's a memory usage snapshot of a week-old Configi process running on a Broadcom MIPS board. The policy is executed every half hour. All 0.9.0 modules compiled in.

    VmPeak:     1356 kB
    VmSize:     1356 kB
    VmLck:         0 kB
    VmPin:         0 kB
    VmHWM:       776 kB
    VmRSS:       776 kB
    VmData:      364 kB
    VmStk:       136 kB
    VmExe:       348 kB
    VmLib:       476 kB
    VmPTE:        12 kB
    VmSwap:        0 kB

It should compile on any recent Linux distributions but it may lack the necessary modules to be useful. This should improve with module contributions for your distribution.

# Download
[configi-0.9.0.tar.xz]()

# Requirements

The only build time requirement is a compiler such as GCC or Clang and the corresponding toolchain.

Runtime Dependencies will depend on the module that you want to compile in. Check the module documentation. The only runtime dependency for the `cfg` binary is a LIBC.

    # ldd bin/cfg
        /lib/ld-musl-x86_64.so.1 (0x7f6167d50000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f6167d50000)

# Building

The build system is a non-recursive Makefile. Unpack the archive, change to the directory then run `make`.

    # tar -xf configi-0.9.0.tar.xz
    # cd configi-0.9.0
    # make

# Running

    # cd configi-0.9.0
    # bin/cfg -vf path_to_your_policy
