import struct, sys
def elf_hash(s):
    if isinstance(s, str): s = s.encode()
    h = 0
    for c in s:
        h = ((h << 4) + c) & 0xffffffff
        g = h & 0xf0000000
        if g: h ^= g >> 24
        h &= ~g & 0xffffffff
    return h
def verfix(path):
    d = bytearray(open(path, 'rb').read())
    e_shoff, = struct.unpack_from('<I', d, 0x20)
    e_shentsize, e_shnum = d[0x2e], struct.unpack_from('<H', d, 0x30)[0]
    secs = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from('<I', d, off + 4)
        sh_offset, sh_size = struct.unpack_from('<II', d, off + 0x10)
        secs.append((sh_type, sh_offset, sh_size))
    ren = {}
    for bad in (b"GLIBC_2.27", b"GLIBC_2.29", b"GLIBC_2.34"):
        # find string in whole file (dynstr); rename in place
        idx = d.find(bad + b"\0")
        while idx >= 0:
            new = b"GLIBC_2.4"
            d[idx:idx+len(bad)+1] = new + b"\0" * (len(bad) - len(new) + 1)
            ren[idx] = elf_hash("GLIBC_2.4")
            idx = d.find(bad + b"\0")
    fixed = 0
    for t, o, sz in secs:
        if t == 0x6ffffffe:  # .gnu.version_r
            p = o
            end = o + sz
            while p + 16 <= end:
                vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from('<HHIII', d, p)
                if vn_version == 0: break
                ap = p + vn_aux
                for _ in range(vn_cnt):
                    vna_hash, vna_flags, vna_other, vna_name, vna_next = struct.unpack_from('<IHHII', d, ap)
                    nameoff = None
                    # vna_name is offset from section start to string (relative to file? .dynstr offset needed)
                    # strings are in dynstr; find by matching our renamed spots: check if ap's name points into a renamed idx
                    # robust: recompute from section link — use dynstr via section link of versym_r
                    if vna_hash == elf_hash(b"GLIBC_2.4"):
                        pass
                    struct.pack_into('<I', d, ap, elf_hash("GLIBC_2.4"))
                    fixed += 1
                    if vna_next == 0: break
                    ap += vna_next
                if vn_next == 0: break
                p += vn_next
    # zero DT_VERSYM
    for t, o, sz in secs:
        if t == 6:
            j = 0
            while j * 8 + 8 <= sz:
                tag, val = struct.unpack_from('<II', d, o + j * 8)
                if tag == 0: break
                if tag == 0x6ffffff0 and val:
                    struct.pack_into('<I', d, o + j * 8 + 4, 0)
                j += 1
    open(path, 'wb').write(d)
    print(f"{path}: renamed {len(ren)} strings, retagged {fixed} vernaux, versym zeroed")
for p in sys.argv[1:]:
    verfix(p)
