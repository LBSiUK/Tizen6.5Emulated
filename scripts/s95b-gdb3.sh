#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
pkill -f '[q]9/qemu-arm-patched -g' 2>/dev/null; sleep 1
nohup setsid chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet /q9/qemu-arm-patched -g 1236 /usr/bin/dotnet /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll --appType inhouse --standalone </dev/null >/tmp/qemu-gdb4.out 2>&1 &
sleep 2
gdb-multiarch -batch \
  -ex "set pagination off" \
  -ex "set architecture arm" \
  -ex "target remote :1236" \
  -ex "handle SIGILL SIG32 SIG33 SIG34 SIG35 pass nostop noprint" \
  -ex "handle SIGSEGV stop nopass" \
  -ex "continue" \
  -ex "echo \n===BT-ALL===\n" \
  -ex "bt 12" \
  -ex "echo \n===FRAME1-CODE===\n" \
  -ex "x/10i \$lr-16" \
  -ex "echo \n===SP-WORDS===\n" \
  -ex "x/32xw \$sp" >/tmp/gdb-out3.txt 2>&1
grep -v "^$" /tmp/gdb-out3.txt | head -70
