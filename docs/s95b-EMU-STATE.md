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

## SESSION-3 (04:00): multi-process TV
- amd RUNS under qemu (real binary): creates /run/aul/daemons/.amd-sock; needs /run/aul/{dbspace,apps,log}.
  Launch: nohup setsid chroot $T env QEMU_CPU=max /q9/qemu-arm-patched /usr/bin/amd (see scripts/s95b-amd2.sh)
- AUL protocol LIVE: sidebar<->amd exchanged 22+ requests (GET_APPID_BYPID, NOTIFY_START, RPC_PORT_PREPARE_STUB...).
  amd's app_info failed (pkgmgr_client -> gdbus -> no dbus): next = stub libpkgmgr-client.so.0
  (amd dlopens it; needs pkgmgr_client_new/free/listen*/set_status_type + pkgmgrinfo_* ~70 fns).
- Sidebar terminate cause: viewdb IPCProxy -> RPCPort.Proxy.Connect("com.samsung.tv.csfs","DGP_STUB") —
  sibling app csfs must RUN. csfs boots under qemu after 22-assembly surgical stage (scripts/s95b-walk.sh);
  then waits /run/.wm_ready (marker), then DIES with NullReferenceException in
  Tizen.NUI.NUICoreBackend.Run — THE DISPLAY GATE: needs a wayland compositor with Tizen
  extensions in the chroot (weston headless + tizen protocol modules, or NUI-native stubs).
- /run markers now: .amd_ready .wm_ready tvs_ready user/5001/{mbr,source}_service_ready

## SESSION-4 (06:40): REAL PIXELS ON VNC 🎉
- DISPLAY STACK UP: Xvnc :2 (port 6969, Leon's existing VNC) hosts weston 13 (x11 backend,
  XDG_RUNTIME_DIR=/home/leonbrahams/s95b-wl -> socket wayland-1) — scripts/s95b-display-up.sh
  (restarts weston if socket gone, bind-mounts socket into chroot /run/user/5001/wayland-1).
- display/tv-pixel-free.c: FREESTANDING ARM wayland client (wl_shm + xdg_shell, raw ARM syscalls,
  _start, no libc — links only tree's libwayland-client/libffi/libdlog-stub; build via
  display/s95b-build-free.sh against wayland-1.18 headers: /tmp/wayland-1.18.0 + /tmp/wl118).
  PROVEN: 1280x720 animated RGB sweep rendering via qemu -> TV libwayland -> weston -> VNC.
  Gotchas burned in: ARM 64-bit syscall args are hi:lo reg pairs (ftruncate64 = r3:r2!),
  memfd_create needs a real name ptr, host wayland headers must match tree's 1.18 era.
- SERVICE STACK: dbus-daemon runs in chroot (needed cynara-ASYNC stubs: cynara_async_* added to
  libcynara-client-async — decision=2/ALLOW via check_cache short-circuit). pkgmgr-server boots,
  registers org.tizen.pkgmgr on the bus, IDLE-EXITS (dbus-activation style) -> scripts/s95b-respawn.sh
  respawner. aul_test launch works end-to-end: amd gets APP_START but rejects csfs because its
  app_info chunk (uid 5001) never populates — amd's pkgmgrinfo scan path still unserved
  (needs pkgmgr-server query serving or a pkgmgrinfo-usr stub). sidebar's OWN pkgmgrinfo direct-DB
  access works (reads /opt/dbspace/.pkgmgr_parser.db — csfs IS installed: tpk/uiapp/dotnet-inhouse).
- NEXT for the app UI: (1) amd app_info population (pkgmgr-server query path or stub),
  (2) then csfs launches with real context -> NUI wayland connect (WESTON READY) ->
  (3) DALi requires tizen_policy/wl_tizen globals + EGL: needs weston tizen-protocol plugin +
  software GLES (mesa softpipe cross-build vs Tizen libc, or COREGL/vendor stubs).

## FINAL WORKING DEMO (03:15)
- tv-pixel-free.c final: compositor bound v4 (damage_buffer needs surface>=4),
  xdg_toplevel_set_fullscreen, dynamic buffer realloc on configure (resize-safe),
  uncapped loop. West: weston --backend=x11 --width=1920 --height=1200 --fullscreen on Xvnc :2.
- Socket delivery: DIRECTORY bind /home/leonbrahams/s95b-wl -> $T/run/user/5001/wl
  (survives weston restarts/socket renames; per-file binds were fragile).
- View from anywhere: ssh -f -N -L 6969:localhost:6969 hpdesk && vnc://localhost:6969
- Result: 88% of the VNC screen filled by the animated ARM-rendered sweep. VERIFIED BY LEON.

## OUTAGE NOTE (03:4x)
hpdesk wedged (OOM): scripts/s95b-respawn.sh while-true loop spawned ~200MB qemu every second
for hours (pkgmgr-server idle-exits). Needs power-cycle. POST-REBOOT SEQUENCE (one command):
  1. ssh works again
  2. bash scripts/s95b-recover.sh   (kills strays, restarts weston+demo for VNC)
  3. mounts: chroot binds died with reboot -> re-run chroot_run.sh mounts + /run markers +
     opt/usr symlinks persist on disk; /dev/shm mkdir again; socket dir-bind via recover script
  4. NO respawn loop — pkgmgr-server/dbus stay OFF unless a test needs them
     (finding: with dbus+pkgmgr-server up, libpkgmgr-info gdbus queries HANG instead of
      falling back to direct DB — the bus made queries WORSE)
  5. pending diagnosis: freestanding libpkgmgr-info tester (tv-pkgtest.c) SIGILLs in a lib ctor
     under QEMU_CPU=max — rerun/decode when box is back

## SESSION-5 (20:00): SOFTWARE GL CHAIN COMPLETE
- /tmp on hpdesk was WIPED at 10:19 (OOM aftermath) — ALL state now lives in ~/s95b-build (SURVIVES).
  qemu+wayland+mesa trees rebuilt there; qemuenv venv + s95b-scripts + patches in ~.
- MOUNTS DIED TOO (no reboot needed, namespace cleanup): scripts/s95b-remount.sh restores all 7 binds.
- pkginfo-server (/usr/bin/pkginfo-server, unit pkgmgr-info.service) = the REAL query service
  (socket /run/pkgmgr-info-server, 0666). NOT dbus, NOT pkgmgr-server (that one = install requests only,
  idle-exits). amd's pkgmgr_client Listen needs dbus+pkgmgr-server alive; queries go to pkginfo-server.
- APP CONTEXT SOLVED: LD_PRELOAD /usr/lib/libappctx-shim.so (overrides aul_app_get_appid_bypid,
  reads APPCTX_APPID env) — csfs passes NUIApp init, reaches WINDOW CREATION.
- MALI EGL replaced by MESA 21.3.9 softpipe (mesa/build-mesa.sh): cross armv7, platforms=wayland,
  gallium=swrast, dri-drivers=[], llvm off. CRITICAL LINK RECIPE (or DllNotFound/GLIBC_2.34):
  explicit Tizen libs on link line (libc.so.6 libpthread.so.0 libdl.so.2 libm.so.6 librt.so.1
  libstdc++.so.6) + time64shim.o + -Wl,-Bstatic -latomic -Wl,-Bdynamic + -static-libgcc.
  System wayland-scanner REPLACED by our 1.18 build (/usr/local/bin + symlink over /usr/bin).
  Tree pc files: ~/s95b-build/pc/{libdrm,expat,zlib,wayland-client,wayland-server}.pc + unversioned
  .so dev symlinks in tree. Deployed: libEGL/GLESv2/glapi/dri+swrast_dri (mali-bak backups kept).
  RUNTIME: LD_PRELOAD libtime64bridge.so (bridges __*_time64 → 32-bit calls) + LIBGL_DRIVERS_PATH=/usr/lib/dri
  GALLIUM_DRIVER=softpipe. DEVERSIONING ELF SURGERY = TOXIC (ld.so segfault) — do NOT use; clean linking only.
- csfs now: context → NUIApp → wm_ready consumed → DALi binder+GL LOAD → crash in ld.so (pc 0x4100cd2c)
  right after libsecurity-privilege-manager/libboost_regex/libcrypt-2.30 load (NUI window creation path).
  NEXT: decode that loader fault (gdbstub on ld.so offset 0xcd2c; check ctor of privilege-manager).
