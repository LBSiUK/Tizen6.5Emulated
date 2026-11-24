import struct, sys
path = sys.argv[1]
data = bytearray(open(path, 'rb').read())
e_phoff, = struct.unpack_from('<I', data, 0x1C)
e_phentsize, e_phnum = struct.unpack_from('<HH', data, 0x2A)
n = 0
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack_from('<8I', data, off)
    if p_type == 1 and (p_flags & 1) and not (p_flags & 2):
        struct.pack_into('<I', data, off + 24, p_flags | 0x2)
        n += 1
open(path, 'wb').write(data)
print(f"rwx-patched {n} LOAD segments")
