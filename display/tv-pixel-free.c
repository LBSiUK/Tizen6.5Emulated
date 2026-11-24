/* S95B emulation pixel proof: freestanding ARM wayland client (no libc).
 * qemu(arm) -> TV libwayland-client -> weston -> Xvnc :1 => VNC 6969. */
#include "wayland-client.h"
#include "xdg-shell-client-protocol.h"

typedef unsigned int u32; typedef int i32; typedef unsigned short u16;
static long __attribute__((naked)) _sys1(long n, long a) {
    __asm volatile("push {r4,r7}\n mov r7, r0\n mov r0, r1\n svc 0\n pop {r4,r7}\n bx lr");
}
static long __attribute__((naked)) _sys3(long n, long a, long b, long c) {
    __asm volatile("push {r4,r7}\n mov r7, r0\n mov r0, r1\n mov r1, r2\n mov r2, r3\n svc 0\n pop {r4,r7}\n bx lr");
}
static long __attribute__((naked)) _sys6(long n, long a, long b, long c, long d, long e, long f) {
    __asm volatile("push {r4-r7,lr}\n mov r7, r0\n mov r0, r1\n mov r1, r2\n mov r2, r3\n ldr r3,[sp,#20]\n ldr r4,[sp,#24]\n ldr r5,[sp,#28]\n svc 0\n pop {r4-r7,pc}");
}
#define SYS_write 4
#define SYS_mmap 192
#define SYS_close 6
#define SYS_memfd 385
#define SYS_ftruncate64 194
#define SYS_exit_group 248
#define SYS_clock_nanosleep 265
#define SYS_lseek 19

static void wlog(const char *s, unsigned n) { _sys3(SYS_write, 2, (long)s, n); }
#define LOG(s) wlog(s, sizeof(s) - 1)
static void loghex(const char *pre, unsigned plen, long v) {
    wlog(pre, plen);
    char b[11]; b[0]='0'; b[1]='x';
    for (int i=9;i>=2;i--) { b[i]="0123456789abcdef"[v & 0xF]; v >>= 4; }
    b[10]='\n';
    wlog(b, 11);
}
static void realloc_buf(int w, int h);
static void *xmmap_anon(unsigned len) {
    return (void *)_sys6(SYS_mmap, 0, len, 3, 0x22, -1, 0); /* PROT_RW|MAP_PRIVATE|ANON */
}
struct ts { long s, ns; };
static void sleep16ms(void) { struct ts t = {0, 16 * 1000 * 1000}; _sys3(SYS_clock_nanosleep, 0, 0, (long)&t); }

static const int W = 1280, H = 720;
static struct wl_display *disp;
static struct wl_compositor *comp;
static struct wl_shm *shm;
static struct xdg_wm_base *wm_base;
static struct wl_surface *surf;
static struct xdg_surface *xsurf;
static struct xdg_toplevel *top;
static u32 *pix;
static int running = 1, configured = 0;
static int cfg_w = 0, cfg_h = 0;
static struct wl_shm_pool *g_pool;
static struct wl_buffer *g_buf;
static int g_fd = 0;

static int xstrcmp(const char *a, const char *b) {
    while (*a && *a == *b) { a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}
static void reg_global(void *d, struct wl_registry *r, u32 name, const char *iface, u32 v) {
    if (!xstrcmp(iface, "wl_compositor")) comp = wl_registry_bind(r, name, &wl_compositor_interface, 4);
    else if (!xstrcmp(iface, "wl_shm")) shm = wl_registry_bind(r, name, &wl_shm_interface, 1);
    else if (!xstrcmp(iface, "xdg_wm_base")) wm_base = wl_registry_bind(r, name, &xdg_wm_base_interface, 1);
}
static void reg_global_remove(void *d, struct wl_registry *r, u32 name) {}
static const struct wl_registry_listener reg_l = { reg_global, reg_global_remove };
static void xdg_configure(void *d, struct xdg_surface *s, u32 serial) { xdg_surface_ack_configure(s, serial); configured = 1; }
static const struct xdg_surface_listener xsurf_l = { xdg_configure };
static void realloc_buf(int w, int h) {
    long size = (long)w * h * 4;
    _sys3(SYS_ftruncate64, g_fd, 0, size);
    pix = (u32 *)_sys6(SYS_mmap, 0x50000000, size, 3, 1, g_fd, 0);
    if ((long)pix < 0 && (long)pix > -4096) { pix = 0; return; }
    if (g_pool) wl_shm_pool_destroy(g_pool);
    g_pool = wl_shm_create_pool(shm, g_fd, size);
    if (g_buf) wl_buffer_destroy(g_buf);
    g_buf = wl_shm_pool_create_buffer(g_pool, 0, w, h, w * 4, WL_SHM_FORMAT_XRGB8888);
    loghex("PIXEL: realloc ", 15, (h << 16) | w);
}
static void top_configure(void *d, struct xdg_toplevel *t, i32 w, i32 h, struct wl_array *st) {
    if (w > 0 && h > 0 && (w != cfg_w || h != cfg_h)) { cfg_w = w; cfg_h = h; realloc_buf(w, h); }
}
static void top_close(void *d, struct xdg_toplevel *t) { running = 0; }
static const struct xdg_toplevel_listener top_l = { top_configure, top_close };
static void wm_ping(void *d, struct xdg_wm_base *b, u32 serial) { xdg_wm_base_pong(b, serial); }
static const struct xdg_wm_base_listener wm_l = { wm_ping };

int main(void) {
    disp = wl_display_connect(NULL);
    if (!disp) { LOG("PIXEL: connect FAILED\n"); return 1; }
    LOG("PIXEL: wayland connected\n");
    struct wl_registry *reg = wl_display_get_registry(disp);
    wl_registry_add_listener(reg, &reg_l, NULL);
    wl_display_roundtrip(disp);
    if (!comp || !shm || !wm_base) { LOG("PIXEL: missing globals\n"); return 2; }
    LOG("PIXEL: globals ok; creating surface\n");
    static const char MFDNAME[] = "tvpix";
    long fd = _sys3(SYS_memfd, (long)MFDNAME, 0, 0);
    loghex("PIXEL: memfd fd=", 17, fd);
    if (fd < 0) return 3;
    long ft = _sys3(SYS_ftruncate64, fd, 0, (W * H * 4)); /* hi:lo pair */
    loghex("PIXEL: ftruncate=", 17, ft);
    long sz = _sys3(SYS_lseek, fd, 0, 2);
    loghex("PIXEL: memfd size=", 18, sz);
    g_fd = fd;
    cfg_w = W; cfg_h = H;
    realloc_buf(W, H);
    if (!pix || !g_buf) { LOG("PIXEL: buffer alloc failed\n"); return 4; }
    surf = wl_compositor_create_surface(comp);
    xsurf = xdg_wm_base_get_xdg_surface(wm_base, surf);
    xdg_surface_add_listener(xsurf, &xsurf_l, NULL);
    top = xdg_surface_get_toplevel(xsurf);
    xdg_toplevel_add_listener(top, &top_l, NULL);
    xdg_toplevel_set_fullscreen(top, NULL);
    wl_surface_commit(surf);
    LOG("PIXEL: drawing (see VNC)\n");
    int frame = 0;
    while (running) {
        if (configured) {
            u32 t = frame * 4;
            for (int y = 0; y < cfg_h; y++) {
                u32 *row = pix + y * cfg_w;
                for (int x = 0; x < cfg_w; x++)
                    row[x] = 0xFF000000u | (((u32)(x + t) & 0xFF) << 16) | (((u32)(y + t / 2) & 0xFF) << 8) | ((u32)((x ^ y) + t) & 0xFF);
            }
            wl_surface_attach(surf, g_buf, 0, 0);
            wl_surface_damage_buffer(surf, 0, 0, cfg_w, cfg_h);
            wl_surface_commit(surf);
        }
        wl_display_dispatch(disp);
        sleep16ms();
        frame++;
        if (frame % 300 == 0) loghex("PIXEL: frames(cfg=", 19, (configured << 24) | (frame & 0xFFFFFF));
    }
    LOG("PIXEL: done\n");
    return 0;
}
void _start(void) {
    int r = main();
    _sys1(SYS_exit_group, r);
    __builtin_unreachable();
}
