#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
B=$T/usr/apps/com.samsung.tv.csfs/bin
SRC="$T/usr/share/dotnet.tizen/tvappapi $T/usr/share/dotnet.tizen/framework $T/usr/share/dotnet.tizen/d.pc $T/usr/share/dotnet.tizen/netcoreapp"
for i in $(seq 1 25); do
  timeout 40 chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet /q9/qemu-arm-patched /usr/bin/dotnet /usr/apps/com.samsung.tv.csfs/bin/csfs.dll --appType inhouse --standalone > /tmp/csfs.log 2>&1
  rc=$?
  miss=$(grep -ao "Could not load file or assembly '[^']*'" /tmp/csfs.log | head -1 | sed "s/Could not load file or assembly '//;s/'$//")
  if [ -z "$miss" ]; then
    echo "ITER $i rc=$rc — no missing assembly"
    grep -avE "^GMAP|^STACKW|^TIZEN-SHMAP" /tmp/csfs.log | tail -8
    break
  fi
  name=$(echo "$miss" | cut -d, -f1)
  found=""
  for s in $SRC/*/; do
    [ -e "$s/$name.dll" ] && found="$s/$name.dll" && break
  done
  if [ -z "$found" ]; then
    echo "ITER $i: $name NOT FOUND anywhere"
    break
  fi
  cp "$found" "$B/"
  echo "ITER $i: staged $name (rc=$rc)"
done
echo "bin size: $(ls $B | wc -l)"
