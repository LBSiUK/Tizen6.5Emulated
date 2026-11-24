#!/bin/bash
exec 2>&1
B=/home/leonbrahams/s95b-build
export PATH=/home/leonbrahams/qemuenv/bin:$PATH
cd $B/qemu-8.2.2
mkdir -p build-arm && cd build-arm
../configure --target-list=arm-linux-user --static --disable-system --disable-tools --disable-docs --disable-guest-agent >/dev/null 2>&1
nice -n 15 make -j4 qemu-arm 2>&1 | tail -2
strings qemu-arm | grep -c "TIZEN-ODDPC\|TIZEN-UNCAUGHT"
cp -f qemu-arm /home/leonbrahams/s95b-tree/root/q9/qemu-arm-patched
cp -f qemu-arm /home/leonbrahams/qemu-arm-tizen
echo "QEMU-REBUILT"
cd $B
[ -d wayland-1.18.0 ] || { curl -sfL https://wayland.freedesktop.org/releases/wayland-1.18.0.tar.xz | tar xj 2>/dev/null || curl -sfL https://wayland.freedesktop.org/releases/wayland-1.18.0.tar.xz -o wl.tgz && tar xf wl.tgz; }
cd wayland-1.18.0
meson setup bw -Ddocumentation=false >/dev/null 2>&1 || meson setup bw4 -Ddocumentation=false >/dev/null 2>&1
ninja -C bw src/wayland-scanner 2>&1 | tail -1 || ninja -C bw4 src/wayland-scanner 2>&1 | tail -1
mkdir -p $B/wl118
SCANNER=$(find bw* -name wayland-scanner -type f | head -1)
$SCANNER client-header protocol/wayland.xml $B/wl118/wayland-client-protocol.h
echo "WAYLAND-REBUILT scanner=$SCANNER"
