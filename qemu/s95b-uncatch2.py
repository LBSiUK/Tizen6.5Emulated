sc = open('/tmp/qemusrc/linux-user/signal.c').read()
# replace GMAP printer with full-line + add stack dump
old_gmap = '''        mf = fopen("/proc/self/maps", "r");
        if (mf) {
            while (fgets(mline, sizeof(mline), mf)) {
                unsigned long long ms, me; char mperms[8];
                if (sscanf(mline, "%llx-%llx %7s", &ms, &me, mperms) == 3) {
                    fprintf(stderr, "GMAP %llx-%llx %s g=%llx %s", ms, me, mperms,
                            (unsigned long long)(ms - guest_base), strchr(mline, '/') ? strrchr(mline, '/') + 1 : "\\n");
                }
            }
            fclose(mf);
        }'''
new_gmap = '''        mf = fopen("/proc/self/maps", "r");
        if (mf) {
            while (fgets(mline, sizeof(mline), mf)) {
                unsigned long long ms, me; char mperms[8]; unsigned long long moff;
                if (sscanf(mline, "%llx-%llx %7s %llx", &ms, &me, mperms, &moff) == 4) {
                    fprintf(stderr, "GMAP %s", mline);
                }
            }
            fclose(mf);
        }
        {
            unsigned long long *sw = (unsigned long long *)g2h_untagged(env->regs[13]);
            int si;
            for (si = 0; si < 48; si++) {
                fprintf(stderr, "STACKW[%d] %llx\\n", si, (unsigned long long)sw[si]);
            }
        }'''
assert old_gmap in sc, "gmap block not found"
sc = sc.replace(old_gmap, new_gmap)
open('/tmp/qemusrc/linux-user/signal.c','w').write(sc)
print("patched v2: full GMAP lines + stack dump")
