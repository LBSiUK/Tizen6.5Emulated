#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
B=/home/leonbrahams/s95b-build
M=$B/mesa-install/lib
cp -a $M/libEGL.so.1.0.0 $M/libGLESv2.so.2.0.0 $M/libglapi.so.0.0.0 $T/usr/lib/
cp -a $M/dri/swrast_dri.so $T/usr/lib/dri/
arm-linux-gnueabi-gcc -shared -fPIC -o $T/usr/lib/libtime64bridge.so /tmp/time64shim.c $T/usr/lib/libc.so.6 $T/usr/lib/libpthread.so.0 -static-libgcc
echo "deployed clean"
SOCK=$(ls -t /home/leonbrahams/s95b-wl/ | grep -E "^wayland-[0-9]+$" | head -1)
cd $T
timeout 120 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet \
  LD_PRELOAD=/usr/lib/libappctx-shim.so:/usr/lib/libtime64bridge.so APPCTX_APPID=com.samsung.tv.csfs \
  XDG_RUNTIME_DIR=/run/user/5001/wl WAYLAND_DISPLAY=$SOCK \
  LIBGL_DRIVERS_PATH=/usr/lib/dri GALLIUM_DRIVER=softpipe \
  /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.csfs/bin/csfs.dll --appType inhouse --standalone > /tmp/csfs-gl.log 2>&1
echo "rc=$?"
grep -aE "EGL|GLES|DALI|swrast|softpipe|MESA|Initialize" /tmp/csfs-gl.log | grep -av SYSTEM_INFO | head -10
echo "=== narration:"
grep -a "\[DLOG" /tmp/csfs-gl.log | grep -avE "Chipset|featureconf|SYSTEM_INFO" | tail -8
