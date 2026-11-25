#!/bin/bash
# Run the real csfs app (Tizen NUI/DALi) under the patched qemu with the
# repaired mesa GL stack -- the "display gate" run.
#
# Needs root (chroot + bind mounts).  Weston must already be up; WL is the
# host directory holding its socket.
exec 2>&1
UH=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
T=${T:-$UH/s95b-tree/root}
TREE=${TREE:-$UH/s95b-tree}
WL=${WL:-/tmp/s95b-wl-host}
LOG=${LOG:-/tmp/csfs-gl.log}
PRE=${PRE:-"/usr/lib/libappctx-shim.so:/usr/lib/libtime64bridge.so:/usr/lib/libglibcxx-assert.so:/usr/lib/libisoc23.so:/usr/lib/libEGL.so.1:/usr/lib/libglapi.so.0"}

pkill -f "[q]9/qemu-arm-patched" 2>/dev/null
mkdir -p $T/opt $T/proc $T/dev $T/tmp $T/usr/gnemul/qemu-arm $T/run/user/5001/wl
mountpoint -q $T/opt || mount --bind "$TREE/opt" $T/opt
mountpoint -q $T/proc || mount -t proc proc $T/proc
mountpoint -q $T/dev || mount --bind /dev $T/dev
mountpoint -q $T/tmp || mount -t tmpfs tmpfs $T/tmp
mountpoint -q $T/usr/gnemul/qemu-arm || mount --bind $T $T/usr/gnemul/qemu-arm
mkdir -p $T/dev/shm && chmod 1777 $T/dev/shm
mkdir -p $T/run/aul/daemons $T/run/aul/apps $T/run/aul/log $T/run/aul/dbspace
umount "$T/run/user/5001/wl" 2>/dev/null
chmod 755 $T/run/user/5001/wl
mount --bind "$WL" "$T/run/user/5001/wl" || echo "WARN: wayland bind failed"
ls -la "$T/run/user/5001/wl" | head -4
touch $T/run/.amd_ready $T/run/.wm_ready $T/run/tvs_ready \
      $T/run/user/5001/mbr_service_ready $T/run/user/5001/source_service_ready

for s in libglibcxx-assert.so libisoc23.so; do [ -f /tmp/$s ] && cp -f /tmp/$s $T/usr/lib/; done
# csfs ships only its own DLLs; the Tizen framework assemblies it loads by name
# (Tizen.TV.FLUX.*) live in /usr/share/dotnet.tizen/framework.  The stock app
# launcher puts that on the probe path, a bare `dotnet csfs.dll` does not -- so
# mirror the layout sidebar's bin has and link them in.
C=$T/usr/apps/com.samsung.tv.csfs/bin
for f in $T/usr/share/dotnet.tizen/framework/*.dll; do
  b=$(basename "$f"); [ -e "$C/$b" ] || ln -s "/usr/share/dotnet.tizen/framework/$b" "$C/$b"
done

cd $T
timeout ${RUNSECS:-180} chroot $T /usr/bin/env \
  QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet \
  LD_PRELOAD="$PRE" APPCTX_APPID=com.samsung.tv.csfs \
  XDG_RUNTIME_DIR=/run/user/5001/wl WAYLAND_DISPLAY=wayland-1 \
  LIBGL_DRIVERS_PATH=/usr/lib/dri GALLIUM_DRIVER=softpipe LIBGL_DEBUG=verbose \
  EGL_LOG_LEVEL=debug WAYLAND_DEBUG=${WAYLAND_DEBUG:-0} \
  /q9/qemu-arm-patched /usr/bin/dotnet \
  /usr/apps/com.samsung.tv.csfs/bin/csfs.dll --appType inhouse --standalone \
  > "$LOG" 2>&1
echo "rc=$?  lines=$(wc -l < "$LOG")  log=$LOG"
grep -a -m1 "TIZEN-UNCAUGHT" "$LOG"
echo "--- gl / dali lines:"
grep -aE "DALI|EGL|GLES|swrast|softpipe|libGL|NUICore" "$LOG" | grep -av SYSTEM_INFO | head -15
echo "--- tail:"
grep -av "^GMAP\|^STACKW" "$LOG" | tail -10
