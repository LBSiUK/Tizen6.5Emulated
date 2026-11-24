#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
pkill -f "[t]mp/tv-pixel" 2>/dev/null; sleep 1
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max XDG_RUNTIME_DIR=/run/user/5001 WAYLAND_DISPLAY=wayland-1 /q9/qemu-arm-patched /tmp/tv-pixel </dev/null >/tmp/tv-pixel.log 2>&1 &
sleep 4
echo "demo alive: $(pgrep -fc '[t]mp/tv-pixel')"
grep -a PIXEL /tmp/tv-pixel.log | tail -3
