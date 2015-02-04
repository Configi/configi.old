#!/bin/sh
/usr/bin/qemu-mipsel -L /sda3/work/sdk/OpenWrt-SDK-brcm47xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2/staging_dir/toolchain-mipsel_mips32_gcc-4.8-linaro_uClibc-0.9.33.2 /sda3/work/musl/root/fossil/configi.src/bin/luac $@
