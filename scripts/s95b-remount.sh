#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
mount --bind /home/leonbrahams/s95b-tree/opt $T/opt && echo "opt"
mount --bind /proc $T/proc && echo "proc"
mount --bind /dev $T/dev 2>/dev/null || mount -t devtmpfs devtmpfs $T/dev && echo "dev"
mount -t tmpfs tmpfs $T/tmp && echo "tmp"
mkdir -p $T/usr/gnemul/qemu-arm
mount --bind $T $T/usr/gnemul/qemu-arm && echo "gnemul self-bind"
mkdir -p $T/dev/shm && chmod 1777 $T/dev/shm
mkdir -p $T/run/aul/daemons $T/run/aul/apps $T/run/aul/log $T/run/aul/dbspace $T/run/user/5001/wl
mkdir -p /home/leonbrahams/s95b-wl
mount --bind /home/leonbrahams/s95b-wl $T/run/user/5001/wl && echo "wayland dir-bind"
touch $T/run/.amd_ready $T/run/.wm_ready $T/run/tvs_ready $T/run/user/5001/mbr_service_ready $T/run/user/5001/source_service_ready
mount | grep -c s95b-tree
