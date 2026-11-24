#!/bin/bash
# usage: walk_deps.sh <app-dll-path-inside-chroot> [max-rounds]
T=/home/leonbrahams/s95b-tree/root
APP="$1"; ROUNDS="${2:-25}"
BIN=$(dirname "$T$APP")
for r in $(seq 1 $ROUNDS); do
  OUT=$(timeout 30 env QEMU_CPU=max chroot "$T" /usr/bin/env DOTNET_ROOT=/usr/share/dotnet /usr/bin/dotnet "$APP" 2>&1)
  MISS=$(echo "$OUT" | grep -oE "Could not load file or assembly '[^,']+" | head -1 | sed "s/Could not load file or assembly '//")
  if [ -z "$MISS" ]; then
    echo "=== round $r: no missing assembly. Output: ==="
    echo "$OUT" | head -25
    exit 0
  fi
  NAME=$(basename "$MISS")
  FOUND=$(find "$T/usr/share/dotnet.tizen" "$T/usr/lib" "$T/usr/apps" -name "$NAME.dll" 2>/dev/null | grep -v "\.ni\." | head -1)
  if [ -z "$FOUND" ]; then
    echo "=== round $r: $MISS NOT FOUND anywhere. Output: ==="; echo "$OUT" | head -12; exit 1
  fi
  cp "$FOUND" "$BIN/" && echo "round $r: + $NAME (from ${FOUND#$T})"
done
echo "=== exhausted $ROUNDS rounds ==="
