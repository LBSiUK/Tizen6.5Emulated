#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
echo "########## RUN 1: MALLOC_CHECK_"
timeout 120 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet MALLOC_CHECK_=3 /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll --appType inhouse --standalone > /tmp/run-mc.log 2>&1
echo "rc=$?"; grep -vE "^GMAP|^STACKW" /tmp/run-mc.log | grep -E "TIZEN-UNCAUGHT|malloc|corrupt|free|invalid|abort" | head -10
echo "########## RUN 2: strace tail"
timeout 120 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet QEMU_STRACE=1 /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll --appType inhouse --standalone > /tmp/run-st.log 2>&1
echo "rc=$?"; grep -vE "^GMAP|^STACKW" /tmp/run-st.log | grep -E "TIZEN-UNCAUGHT" ; grep -E "^[0-9]+ (write|open|mmap2|mprotect|brk|futex|exit)" /tmp/run-st.log | tail -25
