import struct, sys
# Rewrite .gnu.version entries of UNDEFINED symbols to 1 (*global*):
# unversioned lookups match any provider. In-place .so patch.
def deversion(path):
    d = bytearray(open(path, 'rb').read())
    assert d[:4] == b'\x7fELF' and d[4] == 1  # 32-bit LE
    e_shoff, = struct.unpack_from('<I', d, 0x20)
    e_shentsize, e_shnum = d[0x2e], struct.unpack_from('<H', d, 0x30)[0]
    secs = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from('<I', d, off + 4)
        sh_offset, sh_size = struct.unpack_from('<II', d, off + 0x10)
        sh_link, = struct.unpack_from('<I', d, off + 0x18)
        sh_entsize, = struct.unpack_from('<I', d, off + 0x24)
        secs.append((sh_type, sh_offset, sh_size, sh_link, sh_entsize))
    # section headers are gone in stripped/loader view? they exist in our files
    dynsym = dynstr = gnuver = None
    for t, o, sz, ln, es in secs:
        if t == 11: dynsym = (o, sz, es)
        elif t == 3: dynstr = (o, sz)
        elif t == 0x6fffffff: gnuver = (o, sz, es)
    if not (dynsym and gnuver):
        print(f"{path}: no dynsym/version sections, skip"); return
    n = dynsym[1] // dynsym[2]
    changed = 0
    for i in range(n):
        so = dynsym[0] + i * dynsym[2]
        shndx, = struct.unpack_from('<H', d, so + 14)
        vo = gnuver[0] + i * 2
        v, = struct.unpack_from('<H', d, vo)
        if shndx == 0 and v > 1:  # UND + versioned
            struct.pack_into('<H', d, vo, 1)
            changed += 1
    # also neutralize DT_VERNEED / DT_VERNEEDNUM so ld.so skips version validation
    for t, o, sz, ln, es in secs:
        if t == 6:  # SHT_DYNAMIC
            i = 0
            while i * 8 + 8 <= sz:
                tag, val = struct.unpack_from('<II', d, o + i * 8)
                if tag == 0: break
                if tag in (0x6ffffffe, 0x6fffffff):  # VERNEED, VERNEEDNUM
                    struct.pack_into('<I', d, o + i * 8, 30)  # DT_FLAGS, benign duplicate
                    struct.pack_into('<I', d, o + i * 8 + 4, 0)
                i += 1
    open(path, 'wb').write(d)
    print(f"{path}: deversioned {changed} symbols + verneed neutralized")
for p in sys.argv[1:]:
    deversion(p)
