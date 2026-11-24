# Tizen6.5Emulated

Emulating a Samsung S95B TV's (Tizen 6.5 / PontusM, 32-bit ARM hard-float .NET home screen)
complete userspace under `qemu-arm` on an x86-64 Linux box — far enough that the real,
unmodified `HomeSidebar` application boots through CoBA, loads all 34 home components and
starts building the home UI.

Companion work:
- Rooting / eMMC extraction / debloat of the same TV (see the `s95b` sessions)
- Everything here is **defensive emulation of hardware I own**, for building a custom launcher.

## Current state

```
CLR boot → CoBA.Initialize → 34 components → newhome resource loading → UI construction
```

The sidebar now survives 4+ minute runs with zero crashes. The remaining gates are TV
services (`amd` app-manager daemon — which itself boots under the same qemu and creates
`/run/aul/daemons/.amd-sock`) and the display stack (NUI/Wayland).

## Layout

| Path | What it is |
|---|---|
| `qemu/patches/` | qemu 8.2.2 patches (apply with `-p1` inside each file's directory scope) |
| `stubs/` | replacement shared libraries installed into the TV tree |
| `elf-fixers/` | Python ELF surgery for the Tizen linker's malformed LOAD flags |
| `scripts/` | chroot runner, gdb recipes, analysis tools, tree fixers |
| `docs/S95B-EMU-STATE.md` | full working state / run book |

## qemu patches (why each exists)

1. **`01-linux-user-mmap-force-rwx-mprotect-noop-shmap.patch`**
   Samsung's CLR maps read-only files `MAP_SHARED` with write intent (in-place assembly
   patching) and toggles W^X constantly. Force every guest mapping RWX, make guest
   `mprotect()` a no-op, and retry failed shared file mappings as `MAP_PRIVATE` (CoW).
2. **`02-linux-user-sysinfo-procstatus-forgeries.patch`**
   Forge `sysinfo()` to a PontusM-shaped machine and `/proc/self/status` to a
   guest-shaped process so the CLR's memory sizing sees the TV, not the host.
3. **`03-linux-user-fatal-context-dump.patch`**
   On fatal guest signals dump full register set, `/proc/self/maps` and stack words —
   the single most useful debugging aid in this campaign.
4. **`05-arm-tcg-thumb-oddpc-align.patch`**
   CLR native-image (`.ni.dll`) code branches through Thumb-tagged pointers via
   `lookup_and_goto_ptr`, which creates translation blocks at **odd** PCs and trips a
   `tcg` assertion. Align `pc_next` down and continue.

`linux-user/arm/signal.c` must stay **pristine**: earlier "tolerant sigreturn" hacks
corrupted the SIGILL recovery the CLR's CPU feature probes (AES/SHA/CNTPCT execute-and-
catch) depend on.

## Stubs

- **`cynara_stub2.c`** — freestanding (compile `-shared -nostdlib`, see gotchas) ALLOW-all
  cynara replacement; Tizen's privilege checks pass.
- **`dlog_stub.c`** — echoes every `dlog_print` to stderr. Turns the silent app into a
  narrating app; the log *is* the debugger.
- **`pkgcapi_stub2_core.c` + `s95b-genstub2.py`** — smart package-manager CAPI: valid
  handles (heap clones — managed wrappers free them), per-callback clones in `foreach`,
  package roots probed via `manifest.xml`, table from `/tmp/pkgstub.list`.

### Stub build gotchas (hard-won)

- **Never link guest stubs against your cross-toolchain's libc.** Debian's emits
  `GLIBC_2.34` verneed and `__stat64_time64` — the TV is glibc 2.30. Link against the
  *tree's* libc: `arm-linux-gnueabi-gcc -shared -fPIC -Wl,-soname,<soname> x.c $T/usr/lib/libc.so.6 -static-libgcc`
- `-nostdlib` stubs must not reference any libc symbol.
- Keep the SONAME identical to the original library.
- Comment-only patch markers never appear in `strings` — audit binaries via string
  literals or behaviour, not comments.

## Environment recipe (short version)

```
tree:  full rootfs tarred off the live TV, extracted to $T
mount: opt, proc, dev, tmpfs tmp, and self-bind $T → $T/usr/gnemul/qemu-arm
build: qemu 8.2.2 + patches above (arm-linux-user, static)
run:   chroot $T /usr/bin/env QEMU_CPU=max DOTNET_ROOT=/usr/share/dotnet \
           /q9/qemu-arm-patched /usr/bin/dotnet \
           /usr/apps/com.samsung.tv.home.sidebar/bin/HomeSidebar.dll \
           --appType inhouse --standalone
```

`QEMU_CPU=max` is mandatory (default CPU = SIGILL inside the CLR).
See `docs/S95B-EMU-STATE.md` for the complete run book, every fix applied to the tree,
and the current frontier.
