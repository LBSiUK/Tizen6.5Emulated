import sys, re
# usage: mapaddr.py <log> <hexaddr> ...
log = open(sys.argv[1]).read()
gm = []
for l in log.splitlines():
    if l.startswith('GMAP '):
        m = re.match(r'GMAP ([0-9a-f]+)-([0-9a-f]+) (\S+) ([0-9a-f]+) \d+:\d+ \d+\s+(\S+)', l)
        if m: gm.append((int(m.group(1),16), int(m.group(2),16), m.group(3), int(m.group(4),16), m.group(5).strip()))
for a in sys.argv[2:]:
    v = int(a,16)
    hit = next((g for g in gm if g[0] <= v < g[1]), None)
    if hit:
        s,e,perms,off,path = hit
        print(f"{v:#x} -> {path} perms={perms} fileoff={off + (v-s):#x} (+{(v-s):#x} into seg)")
    else:
        print(f"{v:#x} -> UNMAPPED")
