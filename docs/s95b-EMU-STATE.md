# S95B emulation state — 2026-11-24 ~01:30 (after session: signal-fidelity fix + frontier moved to package-manager CAPI)

## Access
- hpdesk from outside LAN: `ssh leonbrahams@81.99.110.162` (LAN: hpdesk/192.168.0.139)
- sudo: `printf '%s\n' 'PW' | sudo -S bash /path/script.sh` — ALWAYS upload script via scp first
  (ssh-heredoc + sudo pipe loses the script stdin). PW ends with a double-quote char.
- chroot tree ~/s95b-tree/root, bind mounts (opt/proc/dev/tmp/gnemul self-bind) STILL LIVE (36d uptime).
- qemu source: /tmp/qemusrc (8.2.2), build: /tmp/qemusrc/build-arm with PATH=/home/leonbrahams/qemuenv/bin
- Canonical binary: deploy BOTH ~/s95b-tree/root/q9/qemu-arm-patched (run target) AND ~/qemu-arm-tizen.

## Run / debug scripts (canonical, on hpdesk)
- /tmp/s95b-run.sh        plain run, log -> ~/sidebar-run.log   (COPIED to ~/s95b-scripts/)
- /tmp/s95b-gdb3.sh       gdbstub run -g 1236, passes SIGILL+SIGRT, stops on SIGSEGV
- /tmp/s95b-diag.sh       MALLOC_CHECK_ / QEMU_STRACE variants
- /tmp/s95b-sym.py        libc vaddr symbolizer (prelinked libc: vaddr = fileoff + 0x42b50000)
NOTE: QEMU_CPU must be in qemu's OWN env (before the qemu binary on the chroot cmd), not guest env.

## Current qemu patch set (source of truth = /tmp/qemusrc)
- linux-user/mmap.c: target_prot |= RWX at top of target_mmap_impl; target_mprotect -> return 0;
  SHMAP/TOPRETRY shared->private retry on EACCES (3 stacked variants, all live)
- linux-user/syscall.c: TIZEN-SYSINFO forge (1.75G total/1.2G free) + open_self_status fake /proc/self/status
- linux-user/signal.c + arm/signal.c: PRISTINE v8.2.2 (NOALTSTACK + sigreturn-tolerance hacks REVERTED —
  they corrupted handler recovery; CPU probe SIGILLs need faithful delivery) + TIZEN-UNCAUGHT dump
  in dump_core_and_abort (regs + full /proc/self/maps lines + 48 stack words at sp).

## Facts learned this session
- guest_base=0: guest VAs == host VAs (0x4xxxxxxx region). Earlier "guest = host-0x40000000" math was wrong.
- "Patches vanished from binary" yesterday was an AUDIT ARTIFACT: comment markers never show in `strings`.
- CPU feature-probe table at guest ~0xc399e6: mrrc p15 CNTPCT / aese / sha1c / sha256h probes, each + bx lr.
  SIGILL recovery works via guest handlers once signal path is faithful.
- r--p guest text pages in host maps = normal TCG write-protection (SMC detection), NOT a bug.
- Tizen libc-2.30.so is PRELINKED: LOAD1 Offset=0 VAddr=0x42b50000; dynsym sparse; use objdump -D.
- Run gets: CLR boot -> CoBA -> ~10 threads -> dozens of assemblies -> REAL sqlite reads of
  /opt/dbspace/.pkgmgr_parser.db -> 2 failed unix connects (ENOENT) -> death. ~4s wall.

## CURRENT FRONTIER (deterministic, all runs)
strlen(0x6f636e75 "unco") fault: pc=0x408a9f44 = libc strlen+4, lr=0x40887d1c inside big static
vfwprintf-family fn (wcsrtombs+strlen pattern, ~file vaddr 0x42ba6xxx-0x42ba8xxx). r0/r1 =
"unco"/"tnoc" ASCII garbage as va_args. Stack frames pass through libcapi-appfw-package-manager.so.
MALLOC_CHECK_=3 no change; gconv(255 mods)+locale-archive present. Died right after CLR opened
Tizen.TV.Application.dll and mmap2'd it PROT_READ|MAP_SHARED (metadata view).

## Next options (ranked)
1. Stub libcapi-appfw-package-manager.so (cynara_stub2 recipe: -shared -nostdlib ARM): return
   PKG_MGR_ERROR / empty package list instead of formatting through broken data. Likely unblocks boot.
2. Decode the 2 failed connect() sockaddrs (qemu strace prints raw ptr; patch to dump bytes) ->
   run minimal dbus/service in chroot.
3. If stubbing: remember the app bin already has full staged deps (205 files incl. capi libs).

## Old session scripts in ~ (root-owned relay of yesterday): reapply_all.sh (BROKEN python),
reapply_clean.py (fixed source patcher), patchstatus/patchsysinfo.py (applied), buildqemu2.sh.
