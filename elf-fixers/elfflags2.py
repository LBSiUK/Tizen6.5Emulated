import struct, sys, os
def fix(path):
    data = bytearray(open(path, 'rb').read())
    if data[:4] != b'\x7fELF' or data[4] != 1: return False
    e_phoff, = struct.unpack_from('<I', data, 0x1C)
    e_phentsize, e_phnum = struct.unpack_from('<HH', data, 0x2A)
    changed = False
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack_from('<8I', data, off)
        if p_type != 1: continue
        if (p_flags & 7) == 0 and p_flags != 0:
            struct.pack_into('<I', data, off + 24, 0x6); changed = True
        elif p_memsz > p_filesz and not (p_flags & 2) and (p_flags & 7) != 0:
            # segment with .bss must be writable
            struct.pack_into('<I', data, off + 24, p_flags | 0x2); changed = True
    if changed: open(path, 'wb').write(data)
    return changed
for p in sys.argv[1:]:
    if fix(p): print(f"fixed {p}")
