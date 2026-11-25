#!/usr/bin/env python3
"""Rename one Verneed version name in place (same length only) and rehash it.

Useful when a lib was cross-built with a newer libstdc++/glibc than the TV
tree provides, but the symbols it actually needs exist under an older version
node.  Same-length rename keeps every offset valid, so it is safe value-level
surgery; the Vernaux hash is recomputed so ld.so can still match the node.

Usage: s95b-verneed-rename.py <elf> <old-name> <new-name>
       (new name must be the same length as the old one)
"""
import struct
import sys

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


def main(path, old, new):
    old_b, new_b = old.encode(), new.encode()
    if len(old_b) != len(new_b):
        sys.exit(f"{path}: lengths differ ({len(old_b)} vs {len(new_b)})")

    d = bytearray(open(path, "rb").read())
    e_shoff, = struct.unpack_from("<I", d, 0x20)
    e_shentsize, = struct.unpack_from("<H", d, 0x2E)
    e_shnum, = struct.unpack_from("<H", d, 0x30)

    verneed = None
    dynstr = None
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from("<I", d, off + 4)
        sh_off, = struct.unpack_from("<I", d, off + 0x10)
        sh_size, = struct.unpack_from("<I", d, off + 0x14)
        sh_link, = struct.unpack_from("<I", d, off + 0x18)
        if sh_type == SHT_GNU_verneed:
            verneed = (sh_off, sh_size, sh_link)
        elif sh_type == 3:                      # SHT_STRTAB
            if dynstr is None:
                dynstr = (sh_off, sh_size)

    if verneed is None:
        sys.exit(f"{path}: no .gnu.version_r")

    voff, vsize, _ = verneed
    # .dynstr is the strtab the verneed section links to
    doff = dsize = None
    off = e_shoff + verneed[2] * e_shentsize
    doff, = struct.unpack_from("<I", d, off + 0x10)
    dsize, = struct.unpack_from("<I", d, off + 0x14)

    renamed = 0
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
            noff = doff + vna_name
            z = d.index(0, noff)
            cur = bytes(d[noff:z])
            if cur == old_b:
                d[noff:z] = new_b
                renamed += 1
                struct.pack_into("<I", d, ap, elf_hash(new_b))
                rehashed += 1
            if vna_next == 0:
                break
            ap += vna_next
        if vn_next == 0:
            break
        p += vn_next

    open(path, "wb").write(d)
    print(f"{path}: renamed {renamed} '{old}' -> '{new}', rehashed {rehashed}")


main(sys.argv[1], sys.argv[2], sys.argv[3])
