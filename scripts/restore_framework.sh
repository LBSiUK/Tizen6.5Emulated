#!/bin/bash
set -e
T=/home/leonbrahams/s95b-tree/root
# restore pristine dotnet.tizen from the streamed tar
tar xf /home/leonbrahams/s95b-images/rootfs.tar -C $T ./usr/share/dotnet.tizen
# clean walk-copied dlls from the app bin
rm -f $T/usr/apps/com.samsung.tv.home.sidebar/bin/Tizen.*.dll $T/usr/apps/com.samsung.tv.home.sidebar/bin/System.*.dll
# install fake cynara
cp /home/leonbrahams/libcynara-client.so.0 $T/usr/lib/libcynara-client.so.0
ls -la $T/usr/lib/libcynara-client.so.0
echo RESTORED
