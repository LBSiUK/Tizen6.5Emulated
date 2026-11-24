#!/bin/bash
exec 2>&1
B=/home/leonbrahams/s95b-build
export PATH=$B/wayland-1.18.0/bw/src:/home/leonbrahams/qemuenv/bin:$PATH
export PKG_CONFIG_PATH=$B/wayland-1.18.0/bw/meson-private:$B/pc
which wayland-scanner
wayland-scanner --version
cd $B/mesa-21.3.9
rm -rf bw2
meson setup bw2 --cross-file $B/mesa-cross.txt \
  -Dplatforms=wayland -Degl=enabled -Dgles1=disabled -Dgles2=enabled \
  -Dgallium-drivers=swrast "-Ddri-drivers=[]" -Dllvm=disabled -Dgbm=disabled -Dglx=disabled \
  -Ddri3=disabled -Dshared-glapi=enabled -Dvulkan-drivers= -Dzstd=disabled \
  -Dbuild-tests=false "-Dtools=[]" \
  -Dc_args="-I$B/armhdr/usr/include -I$B/drmhdr/usr/include -I$B/drmhdr/usr/include/libdrm -I$B/wayland-1.18.0/src -I$B/wayland-1.18.0/egl -I$B/wl118" \
  -Dcpp_args="-I$B/armhdr/usr/include -I$B/drmhdr/usr/include -I$B/drmhdr/usr/include/libdrm -I$B/wayland-1.18.0/src -I$B/wayland-1.18.0/egl -I$B/wl118" \
  -Dc_link_args="-L/home/leonbrahams/s95b-tree/root/usr/lib /home/leonbrahams/s95b-build/time64shim.o /home/leonbrahams/s95b-tree/root/usr/lib/libc.so.6 /home/leonbrahams/s95b-tree/root/usr/lib/libpthread.so.0 /home/leonbrahams/s95b-tree/root/usr/lib/libdl.so.2 /home/leonbrahams/s95b-tree/root/usr/lib/libm.so.6 /home/leonbrahams/s95b-tree/root/usr/lib/librt.so.1 -Wl,-Bstatic -latomic -Wl,-Bdynamic -static-libgcc" -Dcpp_link_args="-L/home/leonbrahams/s95b-tree/root/usr/lib /home/leonbrahams/s95b-build/time64shim.o /home/leonbrahams/s95b-tree/root/usr/lib/libc.so.6 /home/leonbrahams/s95b-tree/root/usr/lib/libpthread.so.0 /home/leonbrahams/s95b-tree/root/usr/lib/libdl.so.2 /home/leonbrahams/s95b-tree/root/usr/lib/libm.so.6 /home/leonbrahams/s95b-tree/root/usr/lib/librt.so.1 /home/leonbrahams/s95b-tree/root/usr/lib/libstdc++.so.6 -Wl,-Bstatic -latomic -Wl,-Bdynamic -static-libgcc" \
  --prefix=$B/mesa-install 2>&1 | tail -3
