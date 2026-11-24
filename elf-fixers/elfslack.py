import struct, sys
path = sys.argv[1]
data = bytearray(open(path, 'rb').read())
assert data[:4] == b'\x7fELF' and data[4] == 1, "not 32-bit LE ELF"
e_phoff, = struct.unpack_from('<I', data, 0x1C)
e_phentsize, e_phnum = struct.unpack_from('<HH', data, 0x2A)
PAGE = 4096
changed = 0
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack_from('<8I', data, off)
    if p_type != 1:  # PT_LOAD
        continue
    if not (p_flags & 2):  # W
        continue
    end = p_vaddr + p_memsz
    new_end = (end + PAGE - 1) & ~(PAGE - 1)
    if new_end > end:
        struct.pack_into('<I', data, off + 24, new_end - p_vaddr)  # p_memsz
        changed += 1
        print(f"LOAD RW vaddr={p_vaddr:#x} memsz {p_memsz:#x} -> {new_end - p_vaddr:#x}")
open(path, 'wb').write(data)
print(f"patched {changed} segments")
