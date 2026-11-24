#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
cd $T
timeout 300 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll --appType inhouse --standalone > /home/leonbrahams/sidebar-run.log 2>&1
echo "rc=$?"
echo "===== last 60 lines ====="
tail -60 /home/leonbrahams/sidebar-run.log
echo "===== line count: $(wc -l < /home/leonbrahams/sidebar-run.log)"
