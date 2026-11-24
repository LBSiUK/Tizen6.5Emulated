#!/bin/bash
exec 2>&1
T=/home/leonbrahams/s95b-tree/root
ls $T/usr/share/dbus-1/system-services/ | grep -i pkgmgr
cat > /tmp/pkgmgr-respawn.sh <<'RS'
#!/bin/bash
while true; do
  chroot /home/leonbrahams/s95b-tree/root /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/pkgmgr-server >>/tmp/pkgmgr.log 2>&1
  sleep 1
done
RS
chmod +x /tmp/pkgmgr-respawn.sh
pkill -f "[p]kgmgr-respawn" 2>/dev/null
nohup setsid /tmp/pkgmgr-respawn.sh </dev/null >/dev/null 2>&1 &
sleep 8
echo "pkgmgr alive: $(pgrep -fc '[q]9/qemu-arm-patched /usr/bin/pkgmgr-server')"
echo "=== launch:"
timeout 20 chroot $T /usr/bin/env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/aul_test launch com.samsung.tv.csfs 2>&1 | grep -a "result" | head -2
sleep 8
echo "=== csfs running:"; pgrep -af "csfs.dll" | head -2
grep -aE "gdbus connection|pkgmgr_client_new" /tmp/amd.log | tail -2
grep -aE "FindAndSetAppInfo|InsertAppInfo|__launch_app|success" /tmp/amd.log | tail -4
