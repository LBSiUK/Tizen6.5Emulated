#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

__attribute__((constructor(101)))
static void make_libs_exec(void) {
    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) return;
    char line[512];
    unsigned long lo, hi;
    char perms[8], path[400];
    while (fgets(line, sizeof(line), f)) {
        path[0] = 0;
        if (sscanf(line, "%lx-%lx %7s %*s %*s %*s %399s", &lo, &hi, perms, path) < 3) continue;
        if (!path[0]) continue;
        if (!strstr(path, ".so")) continue;
        int prot = 0;
        if (perms[0] == 'r') prot |= PROT_READ;
        if (perms[1] == 'w') prot |= PROT_WRITE;
        if (perms[2] == 'x') prot |= PROT_EXEC;
        int want = PROT_READ | PROT_WRITE | PROT_EXEC;
        if (prot != want) {
            mprotect((void*)lo, hi - lo, want);
        }
    }
    fclose(f);
}
