#!/bin/sh
env STAGING_DIR= make AR=mipsel-openwrt-linux-ar CC=mipsel-openwrt-linux-gcc LD=mipsel-openwrt-linux-ld RANLIB=mipsel-openwrt-linux-ranlib STRIP=mipsel-openwrt-linux-strip LUAC=scripts/luac.sh GLUE=scripts/glue.sh
