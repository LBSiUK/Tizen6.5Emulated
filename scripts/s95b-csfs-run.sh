#!/bin/bash
# Run csfs (Edenview) under qemu-arm in the S95B tree, with the display stack
# and the key-router stubs already in place.
#
#   sudo bash scripts/s95b-csfs-run.sh                 # 90s, shots at 20/40/60
#   RUNSECS=180 SHOT_AT=30 sudo -E bash scripts/s95b-csfs-run.sh
#   LOG=/tmp/csfs-x.log SHOTS=3 bash scripts/s95b-csfs-run.sh
#
# Needs: Xvfb + weston already up (scripts/s95b-display-up.sh, which loads
# tizen-keyrouter.so), the tree at ~/s95b-tree/root, and these in /usr/lib:
#   libappctx-shim.so libtime64bridge.so libglibcxx-assert.so libisoc23.so
#   libEGL.so.1 libglapi.so.0 libkrshim2.so (KeyRouter interposer)
# The tree also needs /usr/lib/libsqlite3.so -> libsqlite3.so.0 (created below).
exec 2>&1
UH=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
T=${T:-$UH/s95b-tree/root}
TREE=${TREE:-$UH/s95b-tree}
WL=${WL:-/tmp/s95b-wl-host}
LOG=${LOG:-/tmp/csfs-run.log}
RUNSECS=${RUNSECS:-90}
DISP=${DISP:-:98}
SHOT_AT=${SHOT_AT:-20}
SHOT_EVERY=${SHOT_EVERY:-20}
SHOTS=${SHOTS:-3}
PREFIX=${PREFIX:-/tmp/csfs-shot}

PRE=${PRE:-"/usr/lib/libappctx-shim.so:/usr/lib/libtime64bridge.so:/usr/lib/libglibcxx-assert.so:/usr/lib/libisoc23.so:/usr/lib/libEGL.so.1:/usr/lib/libglapi.so.0:/usr/lib/libkrshim2.so"}

# csfs ships its view plugins in shared/res; the loader only probes bin/.
B=$T/usr/apps/com.samsung.tv.csfs/bin
R=$T/usr/apps/com.samsung.tv.csfs/shared/res
for f in ViewPluginPages.dll ViewPluginFullHomeTiles.dll; do
  [ -e "$B/$f" ] || cp -f "$R/$f" "$B/$f"
done

# .NET asks for "libsqlite3.so"; the TV only ships the versioned soname.
[ -e "$T/usr/lib/libsqlite3.so" ] || ln -sf libsqlite3.so.0 "$T/usr/lib/libsqlite3.so"

[ -f /tmp/libkrshim2.so ] && cp -f /tmp/libkrshim2.so "$T/usr/lib/libkrshim2.so"

pkill -9 -f "[q]9/qemu-arm-patched" 2>/dev/null
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
touch $T/run/.amd_ready $T/run/.wm_ready $T/run/tvs_ready \
      $T/run/user/5001/mbr_service_ready $T/run/user/5001/source_service_ready

cd $T
timeout -k 5 "$RUNSECS" chroot $T /usr/bin/env \
  QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet \
  LD_PRELOAD="$PRE" APPCTX_APPID=com.samsung.tv.csfs \
  XDG_RUNTIME_DIR=/run/user/5001/wl WAYLAND_DISPLAY=wayland-1 \
  LIBGL_DRIVERS_PATH=/usr/lib/dri GALLIUM_DRIVER=softpipe \
  /q9/qemu-arm-patched /usr/bin/dotnet \
  /usr/apps/com.samsung.tv.csfs/bin/csfs.dll --appType inhouse --standalone \
  > "$LOG" 2>&1 &
QPID=$!

sleep "$SHOT_AT"
i=1
while [ "$i" -le "$SHOTS" ]; do
  DISPLAY=$DISP import -window root "${PREFIX}-$i.png" 2>/dev/null && echo "shot $i: ${PREFIX}-$i.png"
  i=$((i + 1))
  [ "$i" -le "$SHOTS" ] && sleep "$SHOT_EVERY"
done
wait $QPID
echo "rc=$?  lines=$(wc -l < "$LOG")  log=$LOG"
echo "--- milestones:"
grep -aE "KeyRouter_Initialize ok|Window .*Show|UpdateRootLayout|Failed to initialize|FileNotFound|NullReference|Stack overflow|TIZEN-UNCAUGHT|db_ready" "$LOG" \
  | cut -c1-170 | head -12
pkill -9 -f "[q]9/qemu-arm-patched" 2>/dev/null
