#!/bin/bash
exec 2>&1
echo "=== state on entry:"
uptime; free -m | head -2
pkill -f "[p]kgmgr-respawn"; echo "respawner killed"
pkill -f "[q]9/qemu-arm-patched /usr/bin/pkgmgr-server"
pkill -f "[q]9/qemu-arm-patched /usr/bin/dbus-daemon"
pkill -f "[q]9/qemu-arm-patched /usr/bin/amd"
pkill -f "[t]mp/tv-pixel"
pkill -f "[q]9/qemu-arm-patched /usr/bin/dotnet"
sleep 2
echo "=== after cleanup:"
free -m | head -2
echo "remaining qemu: $(pgrep -fc qemu-arm)"
echo "=== restart display for Leon:"
T=/home/leonbrahams/s95b-tree/root
if ! pgrep -f "[w]eston --backend" >/dev/null; then
  su -s /bin/bash leonbrahams -c 'DISPLAY=:2 XDG_RUNTIME_DIR=/home/leonbrahams/s95b-wl nohup setsid weston --backend=x11-backend.so --width=1920 --height=1200 --fullscreen </dev/null >/tmp/weston.log 2>&1 &'
  sleep 5
fi
echo "weston: $(pgrep -fc '[w]eston --backend')"
mountpoint -q $T/run/user/5001/wl || mount --bind /home/leonbrahams/s95b-wl $T/run/user/5001/wl
SOCK=$(ls -t /home/leonbrahams/s95b-wl/ | grep -E "^wayland-[0-9]+$" | head -1)
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max XDG_RUNTIME_DIR=/run/user/5001/wl WAYLAND_DISPLAY=$SOCK /q9/qemu-arm-patched /tmp/tv-pixel </dev/null >/tmp/tv-pixel.log 2>&1 &
sleep 4
echo "demo: $(pgrep -fc '[t]mp/tv-pixel')"
free -m | head -2
echo RECOVERY-DONE
