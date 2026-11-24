/* package-manager CAPI smart stub for S95B qemu emulation.
 * Implements the Tizen.Applications-managed subset with valid handles and
 * strdup'd strings (callers free them). Unknown packages are synthesized.
 * Package table (for foreach) read from /tmp/pkgstub.list (pkgid<TAB>path). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct pkg {
    char *id, *label, *type, *version, *icon, *path;
    struct pkg *next;
};
static struct pkg *g_list = NULL;
static int g_init = 0;

static char *xs(const char *s) { char *p = strdup(s ? s : ""); return p; }

static void add_pkg(const char *id, const char *path) {
    struct pkg *p = malloc(sizeof *p);
    p->id = xs(id); p->label = xs(id); p->type = xs("cspapp");
    p->version = xs("1.0"); p->icon = xs("");
    p->path = xs(path && path[0] ? path : "/opt/usr/apps");
    p->next = g_list; g_list = p;
}

static void init_table(void) {
    if (g_init) return; g_init = 1;
    add_pkg("com.samsung.tv.home.sidebar", "/usr/apps/com.samsung.tv.home.sidebar");
    FILE *f = fopen("/tmp/pkgstub.list", "r");
    if (f) {
        char line[512];
        while (fgets(line, sizeof line, f)) {
            char *tab = strchr(line, '\t'); if (!tab) continue;
            *tab = 0; char *path = tab + 1;
            path[strcspn(path, "\r\n")] = 0;
            if (line[0]) add_pkg(line, path);
        }
        fclose(f);
    }
}

static struct pkg *synth(const char *id) {
    init_table();
    for (struct pkg *p = g_list; p; p = p->next)
        if (!strcmp(p->id, id)) return p;
    char path[512]; snprintf(path, sizeof path, "/opt/usr/apps/%s", id);
    add_pkg(id, path);
    return g_list;
}

/* ---- package_info (handle = struct pkg*) ---- */
int package_info_create(const char *package_id, void **out) {
    if (!package_id || !out) return -1;
    *out = synth(package_id); return 0;
}
int package_info_clone(void *info, void **out) {
    struct pkg *p = info; if (!p || !out) return -1;
    struct pkg *n = malloc(sizeof *n); *n = *p;
    n->id = xs(p->id); n->label = xs(p->label); n->type = xs(p->type);
    n->version = xs(p->version); n->icon = xs(p->icon); n->path = xs(p->path);
    n->next = NULL; *out = n; return 0;
}
int package_info_destroy(void *info) {
    struct pkg *p = info; if (!p) return -1;
    free(p->id); free(p->label); free(p->type); free(p->version);
    free(p->icon); free(p->path); free(p); return 0;
}
static int getter_s(void *info, char **out, char *field) {
    if (!info || !out) return -1; *out = xs(field); return 0;
}
int package_info_get_package(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->id); }
int package_info_get_label(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->label); }
int package_info_get_type(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->type); }
int package_info_get_version(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->version); }
int package_info_get_icon(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->icon); }
int package_info_get_path(void *i, char **o) { return getter_s(i,o,((struct pkg*)i)->path); }
int package_info_get_tep_name(void *i, char **o) { (void)i;(void)o; return -1; }

/* ---- package_manager ---- */
int package_manager_get_package_info(const char *package_id, void **out) {
    return package_info_create(package_id, out);
}
typedef int (*pm_cb)(void *info, void *user_data);
int package_manager_foreach_package_info(pm_cb cb, void *ud) {
    init_table();
    if (!cb) return -1;
    for (struct pkg *p = g_list; p; p = p->next)
        if (cb(p, ud) != 1) break;
    return 0;
}
typedef int (*pi_app_cb)(void *app, void *user_data);
int package_info_foreach_app_from_package(void *i, pi_app_cb cb, void *ud) {
    (void)i;(void)cb;(void)ud; return 0;
}
