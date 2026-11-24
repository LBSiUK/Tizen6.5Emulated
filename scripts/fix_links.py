import os
BASE = "/home/leonbrahams/s95b-tree"
fixed = skipped = 0
for sub in ("root", "opt"):
    for dirpath, dirs, files in os.walk(os.path.join(BASE, sub)):
        for name in dirs + files:
            p = os.path.join(dirpath, name)
            if os.path.islink(p):
                tgt = os.readlink(p)
                if tgt.startswith("/"):
                    # guest-absolute -> rewrite as relative to the link's dir
                    host_tgt = os.path.normpath(os.path.join(BASE, "root", tgt.lstrip("/")))
                    if os.path.exists(host_tgt):
                        rel = os.path.relpath(host_tgt, dirpath)
                        os.unlink(p); os.symlink(rel, p); fixed += 1
                    else:
                        skipped += 1
                        if skipped <= 15: print("skip:", p, "->", tgt)
print(f"fixed={fixed} skipped={skipped}")
