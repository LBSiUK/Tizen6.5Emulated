#!/usr/bin/env python3
"""Restore a zeroed DT_VERSYM tag to the real .gnu.version address.

Why this matters (2026-11-24/25):
  Zeroing DT_VERSYM looked like a good way to defeat ld.so 2.30's version-node
  validation for the mesa libs, but it is poison.  glibc's elf_machine_rel()
  does:

      vernum = D_PTR (l, l_info[VERSYMIDX (DT_VERSYM)]);   /* = l_addr + 0 */
      ndx    = vernum[ELF32_R_SYM (reloc->r_info)] & 0x7fff;
      version = &l->l_versions[ndx];

  With d_ptr == 0 the loader reads the library's ELF *header* as a version
  table (0x457f, 0x464c, ... ), gets a nonsense index (e.g. 0x7558) and
  dereferences past the end of l_versions -> SIGSEGV inside ld.so, at
  ld-2.30.so+0xcd2c (lr +0x3b68), exactly matching the S95B crash.

  Fix: put back the address of .gnu.version.  Keep the verneed string renames
  (GLIBC_2.4) -- those make the version nodes resolvable on glibc 2.30.

Usage: s95b-versymfix.py <elf> [<elf> ...]
Exit code 0 always; prints one line per file.
"""
import struct
import sys


def fix(path):
    d = bytearray(open(path, "rb").read())
    if d[:4] != b"\x7fELF" or d[4] != 1:
        print(f"{path}: not ELF32")
        return
    e_shoff, = struct.unpack_from("<I", d, 0x20)
    e_shentsize, = struct.unpack_from("<H", d, 0x2e)
    e_shnum, = struct.unpack_from("<H", d, 0x30)

    # 1. locate SHT_GNU_versym (0x6fffffff) -> its virtual address
    versym_addr = None
    dyn = None
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from("<I", d, off + 4)
        sh_addr, = struct.unpack_from("<I", d, off + 0x0c)
        sh_off, = struct.unpack_from("<I", d, off + 0x10)
        sh_size, = struct.unpack_from("<I", d, off + 0x14)
        if sh_type == 0x6FFFFFFF:          # SHT_GNU_versym
            versym_addr = sh_addr
        elif sh_type == 6:                 # SHT_DYNAMIC
            dyn = (sh_off, sh_size)

    if versym_addr is None:
        print(f"{path}: no .gnu.version, nothing to do")
        return
    if dyn is None:
        print(f"{path}: no .dynamic")
        return

    # 2. walk .dynamic for DT_VERSYM (0x6ffffff0)
    off, size = dyn
    j = 0
    changed = None
    while j * 8 + 8 <= size:
        tag, val = struct.unpack_from("<II", d, off + j * 8)
        if tag == 0:
            break
        if tag == 0x6FFFFFF0:
            changed = val
            if val != versym_addr:
                struct.pack_into("<I", d, off + j * 8 + 4, versym_addr)
            break
        j += 1

    if changed is None:
        print(f"{path}: no DT_VERSYM tag (versym addr 0x{versym_addr:x})")
        return
    if changed == versym_addr:
        print(f"{path}: ok already (DT_VERSYM 0x{changed:x})")
        return
    open(path, "wb").write(d)
    print(f"{path}: DT_VERSYM 0x{changed:x} -> 0x{versym_addr:x}")


for p in sys.argv[1:]:
    fix(p)
