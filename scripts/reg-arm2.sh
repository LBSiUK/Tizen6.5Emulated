#!/bin/bash
[ -e /proc/sys/fs/binfmt_misc/qemu-arm ] && echo -1 > /proc/sys/fs/binfmt_misc/qemu-arm
printf '%b' "$(cat /tmp/regline)" > /proc/sys/fs/binfmt_misc/register && echo REGISTERED
head -3 /proc/sys/fs/binfmt_misc/qemu-arm
/home/leonbrahams/s95b-tree/root/usr/bin/env --version 2>&1 | head -1
