#!/bin/bash
# S95B emulation: cross-build mesa (softpipe software GL) for Tizen armv7.
# Produces libEGL.so.1 + libGLESv2.so.2 + libglapi + gallium softpipe for the TV tree.
set -ex
T=/home/leonbrahams/s95b-tree/root
cd /tmp
[ -d mesa-21.3.9 ] || { curl -sfL https://archive.mesa3d.org/mesa-21.3.9.tar.xz -o mesa.tar.xz && tar xf mesa.tar.xz; }
cd mesa-21.3.9
export PATH=/home/leonbrahams/qemuenv/bin:$PATH
export PKG_CONFIG_LIBDIR=$T/usr/lib/pkgconfig:$T/usr/share/pkgconfig
cat > /tmp/mesa-cross.txt <<'XEOF'
[binaries]
c = 'arm-linux-gnueabi-gcc'
cpp = 'arm-linux-gnueabi-g++'
ar = 'arm-linux-gnueabi-ar'
strip = 'arm-linux-gnueabi-strip'
pkgconfig = 'pkg-config'
[host_machine]
system = 'linux'
cpu_family = 'arm'
cpu = 'armv7'
endian = 'little'
XEOF
# headers: wayland 1.18 build + tree sysroot
mkdir -p /tmp/mesa-sysroot/include /tmp/mesa-sysroot/lib
cp -r /tmp/wayland-1.18.0/src/*.h /tmp/mesa-sysroot/include/ 2>/dev/null || true
cp -r /tmp/wl118/*.h /tmp/mesa-sysroot/include/ 2>/dev/null || true
meson setup bw --cross-file /tmp/mesa-cross.txt \
  -Dplatforms=wayland -Degl=true -Dgles1=disabled -Dgles2=enabled \
  -Dgallium-drivers=softpipe -Dllvm=disabled -Dgbm=disabled -Dglx=disabled \
  -Ddri3=disabled -Dshared-glapi=enabled -Dvulkan-drivers= \
  -Dzlib=enabled -Dexpat=enabled -Dlibdir=lib \
  -Dc_args="-I/tmp/mesa-sysroot/include -I$T/usr/include" \
  -Dcpp_args="-I/tmp/mesa-sysroot/include -I$T/usr/include" \
  -Dc_link_args="-L$T/usr/lib" -Dcpp_link_args="-L$T/usr/lib"
ninja -C bw
ls -la bw/src/egl/main/libEGL.so* bw/src/gallium/targets/libGLESv2.so* 2>/dev/null
