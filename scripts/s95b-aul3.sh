#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
echo "=== pre: amd pkgmgr state:"
grep -aE "pkgmgr_client|Listen" /tmp/amd.log | head -4
echo "=== launching csfs:"
timeout 15 chroot $T /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/aul_test launch com.samsung.tv.csfs 2>&1 | head -8
echo "rc=$?"
sleep 5
echo "=== amd log tail:"
grep -aE "Launch|launch|exec|fork|csfs" /tmp/amd.log | tail -10
echo "=== running apps:"
pgrep -af "qemu-arm.*csfs" | head -3
