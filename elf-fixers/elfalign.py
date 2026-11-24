import struct, sys
path = sys.argv[1]
data = bytearray(open(path, 'rb').read())
e_phoff, = struct.unpack_from('<I', data, 0x1C)
e_phentsize, e_phnum = struct.unpack_from('<HH', data, 0x2A)
PAGE = 4096
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack_from('<8I', data, off)
    if p_type != 1 or not (p_flags & 2):
        continue
    if p_vaddr % PAGE:
        back = p_vaddr % PAGE
        new_vaddr = p_vaddr - back
        new_offset = p_offset - back
        if new_offset < 0:
            continue
        struct.pack_into('<8I', data, off, p_type, new_offset, new_vaddr, p_paddr, p_filesz + back, p_memsz + back, p_flags, p_align)
        print(f"RW seg: vaddr {p_vaddr:#x}->{new_vaddr:#x}, offset {p_offset:#x}->{new_offset:#x}, sizes +{back:#x}")
        break
open(path, 'wb').write(data)
print("done")
