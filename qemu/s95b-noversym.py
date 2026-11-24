import struct, sys
def noversym(path):
    d = bytearray(open(path, 'rb').read())
    e_shoff, = struct.unpack_from('<I', d, 0x20)
    e_shentsize, e_shnum = d[0x2e], struct.unpack_from('<H', d, 0x30)[0]
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_type, = struct.unpack_from('<I', d, off + 4)
        if sh_type != 6: continue  # SHT_DYNAMIC
        sh_offset, sh_size = struct.unpack_from('<II', d, off + 0x10)
        j = 0
        while j * 8 + 8 <= sh_size:
            tag, val = struct.unpack_from('<II', d, sh_offset + j * 8)
            if tag == 0: break
            if tag == 0x6ffffff0 and val:  # DT_VERSYM
                struct.pack_into('<I', d, sh_offset + j * 8 + 4, 0)
                print(f"{path}: DT_VERSYM val {val:#x} -> 0")
            j += 1
        break
    open(path, 'wb').write(d)
for p in sys.argv[1:]:
    noversym(p)
