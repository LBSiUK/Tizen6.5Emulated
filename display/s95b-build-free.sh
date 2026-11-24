#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
WL=/tmp/wayland-1.18.0/src
INC="-I/tmp -I/tmp/wl118 -I$WL"
arm-linux-gnueabi-gcc -c -fPIC -o /tmp/xdg-code.o /tmp/xdg-code.c $INC
arm-linux-gnueabi-gcc -nostdlib -fno-stack-protector -o /tmp/tv-pixel /tmp/tv-pixel-free.c /tmp/xdg-code.o $INC \
  -Wl,-dynamic-linker,/lib/ld-linux.so.3 \
  $T/usr/lib/libwayland-client.so.0 $T/usr/lib/libffi.so.7 $T/usr/lib/libdlog.so.0 \
  -lgcc -Wl,--allow-shlib-undefined && echo BUILT
arm-linux-gnueabi-readelf -d /tmp/tv-pixel | grep -E "NEEDED"
arm-linux-gnueabi-readelf -V /tmp/tv-pixel | grep -c "GLIBC_2.3[0-9]" || true
cp /tmp/tv-pixel $T/tmp/
echo "=== run under qemu (30s):"
timeout 30 chroot $T /usr/bin/env QEMU_CPU=max XDG_RUNTIME_DIR=/run/user/5001 WAYLAND_DISPLAY=wayland-1 /q9/qemu-arm-patched /tmp/tv-pixel 2>&1 | head -10
