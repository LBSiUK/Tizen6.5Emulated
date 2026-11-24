#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
mkdir -p $T/run/aul/dbspace $T/run/aul/apps $T/run/aul/log
pkill -f "[q]9/qemu-arm-patched /usr/bin/amd" 2>/dev/null; sleep 1
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/amd </dev/null >/tmp/amd.log 2>&1 &
sleep 8
echo "amd alive: $(pgrep -fc '[q]9/qemu-arm-patched /usr/bin/amd')"
ls -la $T/run/aul/daemons/.amd-sock
grep -aE "READY|listening|server socket|error|failed" /tmp/amd.log | tail -6
echo "=== sidebar run with amd alive:"
timeout 240 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll --appType inhouse --standalone > /home/leonbrahams/sidebar-run.log 2>&1
echo "rc=$?"
echo "narration: $(grep -ac DLOG /home/leonbrahams/sidebar-run.log)"
grep -a "TIZEN-UNCAUGHT\|Assertion\|Unhandled" /home/leonbrahams/sidebar-run.log | head -3
