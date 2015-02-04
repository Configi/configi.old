#!/bin/sh
SDK=""
/usr/bin/qemu-mipsel -L $SDK/OpenWrt-SDK-brcm47xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2/staging_dir/toolchain-mipsel_mips32_gcc-4.8-linaro_uClibc-0.9.33.2 bin/luac $@
