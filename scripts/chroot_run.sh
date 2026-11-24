#!/bin/bash
# usage: chroot_run.sh <guest command...>
T=/home/leonbrahams/s95b-tree/root
rm -f $T/opt
mkdir -p $T/opt $T/proc
mountpoint -q $T/opt || mount --bind /home/leonbrahams/s95b-tree/opt $T/opt
mountpoint -q $T/proc || mount --bind /proc $T/proc
cp /hello.dll $T/ 2>/dev/null || true
chroot $T /usr/bin/env DOTNET_ROOT=/usr/share/dotnet "$@"
