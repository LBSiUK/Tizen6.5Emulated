#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
mkdir -p $T/run/dbus $T/var/lib/dbus $T/var/run
[ -s $T/var/lib/dbus/machine-id ] || echo "s95bqemu$(date +%s)" | cut -c1-32 > $T/var/lib/dbus/machine-id
ln -sf /var/lib/dbus/machine-id $T/etc/machine-id 2>/dev/null
pkill -f "[q]9/qemu-arm-patched /usr/bin/dbus-daemon" 2>/dev/null; sleep 1
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/dbus-daemon --system --nopidfile </dev/null >/tmp/dbus.log 2>&1 &
sleep 4
echo "dbus alive: $(pgrep -fc '[q]9/qemu-arm-patched /usr/bin/dbus-daemon')"
ls -la $T/run/dbus/ 2>/dev/null | awk '{print $9}'
grep -avE "^GMAP|^STACKW" /tmp/dbus.log | head -5
echo "=== pkgmgr-server:"
pkill -f "[q]9/qemu-arm-patched /usr/bin/pkgmgr-server" 2>/dev/null; sleep 1
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/pkgmgr-server </dev/null >/tmp/pkgmgr.log 2>&1 &
sleep 6
echo "pkgmgr alive: $(pgrep -fc '[q]9/qemu-arm-patched /usr/bin/pkgmgr-server')"
grep -avE "^GMAP|^STACKW" /tmp/pkgmgr.log | head -8
