import subprocess, re
T='/home/leonbrahams/s95b-tree/root'
LIB=T+'/usr/lib/libc-2.30.so'
ph = subprocess.run(['arm-linux-gnueabi-readelf','-lW',LIB],capture_output=True,text=True).stdout
loads=[]
for l in ph.splitlines():
    m = re.match(r'\s*LOAD\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)', l)
    if m:
        off, va, fsz = int(m.group(2),16), int(m.group(1),16), int(m.group(4),16)
        loads.append((off, va, fsz))
print("LOADs (off, vaddr, filesz):", [(hex(a),hex(b),hex(c)) for a,b,c in loads])
def vaddr_for(fo):
    for off,va,fsz in loads:
        if off <= fo < off+fsz: return va + (fo-off)
    return None
pc_v = vaddr_for(0x79000+0xf44); lr_v = vaddr_for(0x56000+0xd1c)
print("pc vaddr:", hex(pc_v) if pc_v else None, " lr vaddr:", hex(lr_v) if lr_v else None)
for name, v in [('pc',pc_v),('lr',lr_v)]:
    d = subprocess.run(['arm-linux-gnueabi-objdump','-D',f'--start-address={v-0x2c}',f'--stop-address={v+0x14}',LIB],capture_output=True,text=True).stdout
    print(f"=== {name} @ {v:#x} ===")
    print('\n'.join(d.splitlines()[6:22]))
