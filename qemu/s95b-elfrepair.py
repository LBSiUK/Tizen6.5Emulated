#!/usr/bin/env python3
"""Repair the DT_VERSYM / DT_VERNEED tags in the cross-built mesa libs.

Background (2026-11-24/25, S95B emulation):

  Earlier sessions "defeated" ld.so 2.30's version-node validation on these
  libs by
    * zeroing DT_VERSYM (qemu/s95b-verfix.py, s95b-noversym.py), and
    * overwriting DT_VERNEED (and DT_VERNEEDNUM) with two junk DT_FLAGS
      entries -- visible as three DT_FLAGS tags, two of them with value 0.

  Both tricks are poison.  glibc's elf_machine_rel() does

      vernum  = D_PTR (l, l_info[VERSYMIDX (DT_VERSYM)]);   /* l_addr + 0 */
      ndx     = vernum[ELF32_R_SYM (reloc->r_info)] & 0x7fff;
      version = &l->l_versions[ndx];

  With d_ptr == 0 the loader reads the library's ELF *header* as the version
  table (0x457f = "\x7fE", 0x464c = "LF", ...) and gets a nonsense index.
  And because DT_VERNEED is gone, _dl_check_map_versions() never allocates
  l_versions at all, so &l_versions[ndx] is a NULL+16 dereference:

      SIGSEGV in ld-2.30.so+0xcd2c (return addr +0x3b68), r0=0

  which is exactly the crash that blocked csfs and every EGL probe.

What this script does (value-level only, no structural ELF surgery):

  1. DT_VERSYM  := vaddr of .gnu.version          (if it is 0)
  2. one junk DT_FLAGS(0) slot := (DT_VERNEED, vaddr of .gnu.version_r)
  3. one more junk DT_FLAGS(0) slot := (DT_VERNEEDNUM, count of Verneed entries)
  4. every Vernaux.vna_hash := elf_hash(its own version name)

  Step 4 matters because s95b-verfix.py rewrote *all* vna_hash values to
  elf_hash("GLIBC_2.4") while only renaming the GLIBC_2.27/29/34 strings.
  ld.so matches version nodes by (hash, name), so a correct name with a
  foreign hash is reported as "version `GLIBC_2.8' not found" even though
  the TV's libc does define GLIBC_2.8.

  It leaves the GLIBC_2.4 string renames (qemu/s95b-verfix.py) alone: those
  are what let the version nodes resolve on the TV's glibc 2.30, and they are
  harmless.  STATIC_TLS is left as found (clearing it is not required for
  this crash; qemu/s95b-notls.py is a separate, optional hack).

Usage: s95b-elfrepair.py <elf> [<elf> ...]     (idempotent)
"""
import struct
import sys

DT_FLAGS = 0x1E
DT_VERSYM = 0x6FFFFFF0
DT_VERNEED = 0x6FFFFFFE
DT_VERNEEDNUM = 0x6FFFFFFF
SHT_DYNAMIC = 6
SHT_GNU_versym = 0x6FFFFFFF
SHT_GNU_verneed = 0x6FFFFFFE


def elf_hash(name):
    h = 0
    for c in name:
        h = ((h << 4) + c) & 0xFFFFFFFF
        g = h & 0xF0000000
        if g:
            h ^= g >> 24
        h &= ~g & 0xFFFFFFFF
    return h


def repair(path):
    d = bytearray(open(path, "rb").read())
    if d[:4] != b"\x7fELF" or d[4] != 1:
        print(f"{path}: not an ELF32 file")
        return

    e_shoff, = struct.unpack_from("<I", d, 0x20)
    e_shentsize, = struct.unpack_from("<H", d, 0x2E)
    e_shnum, = struct.unpack_from("<H", d, 0x30)

    versym_addr = verneed_addr = None
    verneed_count = 0
    verneed = None          # (file_off, size, sh_link)
    dyn = None
    secs = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from("<I", d, off + 4)
        sh_addr, = struct.unpack_from("<I", d, off + 0x0C)
        sh_off, = struct.unpack_from("<I", d, off + 0x10)
        sh_size, = struct.unpack_from("<I", d, off + 0x14)
        sh_link, = struct.unpack_from("<I", d, off + 0x18)
        secs.append((sh_type, sh_addr, sh_off, sh_size, sh_link))
        if sh_type == SHT_GNU_versym:
            versym_addr = sh_addr
        elif sh_type == SHT_GNU_verneed:
            verneed_addr = sh_addr
            verneed = (sh_off, sh_size, sh_link)
            # count Verneed entries by walking vn_next
            p, end = sh_off, sh_off + sh_size
            while p + 16 <= end:
                vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from(
                    "<HHIII", d, p)
                if vn_version == 0:
                    break
                verneed_count += 1
                if vn_next == 0:
                    break
                p += vn_next
        elif sh_type == SHT_DYNAMIC:
            dyn = (sh_off, sh_size)

    if dyn is None:
        print(f"{path}: no .dynamic")
        return

    off, size = dyn
    slots = []          # (index, tag, value)
    j = 0
    while j * 8 + 8 <= size:
        tag, val = struct.unpack_from("<II", d, off + j * 8)
        if tag == 0:
            break
        slots.append((j, tag, val))
        j += 1

    changes = []

    # 1. DT_VERSYM
    sym_slot = next((s for s in slots if s[1] == DT_VERSYM), None)
    if versym_addr is not None and sym_slot is not None and sym_slot[2] != versym_addr:
        struct.pack_into("<I", d, off + sym_slot[0] * 8 + 4, versym_addr)
        changes.append(f"VERSYM 0x{sym_slot[2]:x}->0x{versym_addr:x}")

    has_verneed = any(s[1] == DT_VERNEED for s in slots)
    junk = [s for s in slots if s[1] == DT_FLAGS and s[2] == 0]
    if verneed_addr is not None and not has_verneed:
        if not junk:
            print(f"{path}: no DT_VERNEED and no free DT_FLAGS(0) slot to reuse")
        else:
            idx = junk.pop(0)[0]
            struct.pack_into("<II", d, off + idx * 8, DT_VERNEED, verneed_addr)
            changes.append(f"DT_FLAGS(0)@[{idx}]->VERNEED 0x{verneed_addr:x}")
            if not any(s[1] == DT_VERNEEDNUM for s in slots) and junk:
                idx = junk.pop(0)[0]
                struct.pack_into("<II", d, off + idx * 8, DT_VERNEEDNUM, verneed_count)
                changes.append(f"DT_FLAGS(0)@[{idx}]->VERNEEDNUM {verneed_count}")

    # 4. recompute Vernaux hashes from their own names
    if verneed is not None:
        voff, vsize, vlink = verneed
        if vlink < len(secs):
            _, _, doff, dsize, _ = secs[vlink]
            rehashed = 0
            p, end = voff, voff + vsize
            while p + 16 <= end:
                vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from(
                    "<HHIII", d, p)
                if vn_version == 0:
                    break
                ap = p + vn_aux
                for _ in range(vn_cnt):
                    vna_hash, vna_flags, vna_other, vna_name, vna_next = \
                        struct.unpack_from("<IHHII", d, ap)
                    name_off = doff + vna_name
                    if name_off >= doff + dsize:
                        break
                    z = d.index(0, name_off)
                    want = elf_hash(bytes(d[name_off:z]))
                    if vna_hash != want:
                        struct.pack_into("<I", d, ap, want)
                        rehashed += 1
                    if vna_next == 0:
                        break
                    ap += vna_next
                if vn_next == 0:
                    break
                p += vn_next
            if rehashed:
                changes.append(f"rehashed {rehashed} vernaux")

    if changes:
        open(path, "wb").write(d)
        print(f"{path}: " + "; ".join(changes))
    else:
        print(f"{path}: already sane")


for p in sys.argv[1:]:
    repair(p)
