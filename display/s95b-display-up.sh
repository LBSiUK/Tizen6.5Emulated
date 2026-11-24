#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
# restart weston if socket missing
if [ ! -S /home/leonbrahams/s95b-wl/wayland-1 ]; then
  pkill -f "[w]eston --backend" 2>/dev/null; sleep 1
  rm -f /home/leonbrahams/s95b-wl/wayland-1*
  su -s /bin/bash leonbrahams -c 'DISPLAY=:2 XDG_RUNTIME_DIR=/home/leonbrahams/s95b-wl nohup setsid weston --backend=x11-backend.so </dev/null >/tmp/weston.log 2>&1 &'
  sleep 5
fi
ls -la /home/leonbrahams/s95b-wl/ | awk '{print $9}'
echo "weston alive: $(pgrep -fc '[w]eston --backend')"
# rebind
umount $T/run/user/5001/wayland-1 2>/dev/null
rm -f $T/run/user/5001/wayland-1; touch $T/run/user/5001/wayland-1
mount --bind /home/leonbrahams/s95b-wl/wayland-1 $T/run/user/5001/wayland-1 && echo "socket bound"
rm -f /tmp/tp-run.log
timeout 20 chroot $T /usr/bin/env QEMU_CPU=max XDG_RUNTIME_DIR=/run/user/5001 WAYLAND_DISPLAY=wayland-1 /q9/qemu-arm-patched /tmp/tv-pixel > /tmp/tp-run.log 2>&1
echo "rc=$?"
grep -a "PIXEL" /tmp/tp-run.log | head -8
