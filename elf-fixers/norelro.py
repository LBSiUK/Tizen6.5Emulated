import struct, sys
path = sys.argv[1]
data = bytearray(open(path, 'rb').read())
e_phoff, = struct.unpack_from('<I', data, 0x1C)
e_phentsize, e_phnum = struct.unpack_from('<HH', data, 0x2A)
n = 0
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type, = struct.unpack_from('<I', data, off)
    if p_type == 0x6474e552:  # PT_GNU_RELRO
        struct.pack_into('<I', data, off, 0)
        n += 1
open(path, 'wb').write(data)
print(f"removed {n} PT_GNU_RELRO")
