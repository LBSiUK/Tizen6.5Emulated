#!/bin/bash
# Bring up the headless display stack for the S95B emulation: Xvfb + weston.
#
# DALi needs a compositor that offers a *seat* (headless weston does not, and
# csfs dies with "Failed to initializeDaliWindow, Error type: WaylandInput").
# Weston's x11 backend always advertises keyboard+pointer, so Xvfb alone is
# enough - no real GPU and no VNC required.
#
#   XDG_RUNTIME_DIR must be the dir the chroot bind-mounts to /run/user/5001/wl
#   (default /tmp/s95b-wl-host, matching scripts/s95b-csfs-gl.sh).
set -u
DISP=${DISP:-:98}
WL=${WL:-/tmp/s95b-wl-host}
SOCK=${SOCK:-wayland-1}
GEOM=${GEOM:-1920x1200x24}

mkdir -p "$WL"; chmod 700 "$WL"

xok() { DISPLAY=$DISP xdpyinfo >/dev/null 2>&1; }
if ! xok; then
  pkill -f "Xvfb $DISP " 2>/dev/null; sleep 1
  nohup Xvfb "$DISP" -screen 0 "$GEOM" -nolisten tcp >/tmp/xvfb.log 2>&1 &
  for i in 1 2 3 4 5 6 7 8; do sleep 1; xok && break; done
  xok && echo "started Xvfb $DISP" || { echo "FATAL: Xvfb $DISP not responding (try DISP=:97)"; exit 1; }
fi

if ! pgrep -f "weston .*--socket=$SOCK" >/dev/null; then
  pkill -f "weston --backend" 2>/dev/null
  rm -f "$WL/$SOCK" "$WL/$SOCK.lock"
  DISPLAY=$DISP XDG_RUNTIME_DIR=$WL nohup weston \
    --backend=x11 --width=${GEOM%%x*} --height=$(echo "$GEOM" | cut -dx -f2) \
    --socket=$SOCK --idle-time=0 >/tmp/weston.log 2>&1 &
  sleep 3
  echo "started weston on $DISP, socket $WL/$SOCK"
fi

ls -l "$WL" | tail -3
echo "DISPLAY=$DISP  XDG_RUNTIME_DIR=$WL  WAYLAND_DISPLAY=$SOCK"
echo "screenshot: DISPLAY=$DISP import -window root /tmp/shot.png"
