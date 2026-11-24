/* S95B emu: bridge glibc's y2038 *_time64 symbols down to the 32-bit variants
 * present in Tizen's glibc 2.30. ABI-identical on armv7 for our usage. */
#include <stdarg.h>
typedef struct { long opaque[16]; } shim_stat;
int __fstat64_time64(int fd, shim_stat *st);
int __fstat64_time64(int fd, shim_stat *st) { return fstat64(fd, (void *)st); }
int __stat64_time64(const char *p, shim_stat *st);
int __stat64_time64(const char *p, shim_stat *st) { return stat64(p, (void *)st); }
int __lstat64_time64(const char *p, shim_stat *st);
int __lstat64_time64(const char *p, shim_stat *st) { return lstat64(p, (void *)st); }
int __fcntl_time64(int fd, int cmd, ...);
int __fcntl_time64(int fd, int cmd, ...) {
    va_list ap; va_start(ap, cmd); long a = va_arg(ap, long); va_end(ap);
    return fcntl(fd, cmd, a);
}
int __open64_time64(const char *p, int fl, ...);
int __open64_time64(const char *p, int fl, ...) {
    va_list ap; va_start(ap, fl); int m = va_arg(ap, int); va_end(ap);
    return open64(p, fl, m);
}
int __open_time64(const char *p, int fl, ...);
int __open_time64(const char *p, int fl, ...) {
    va_list ap; va_start(ap, fl); int m = va_arg(ap, int); va_end(ap);
    return open(p, fl, m);
}
int __fstatat64_time64(int fd, const char *p, shim_stat *st, int fl);
int __fstatat64_time64(int fd, const char *p, shim_stat *st, int fl) { return fstatat64(fd, p, (void *)st, fl); }
int __ioctl_time64(int fd, unsigned long req, void *arg);
int __ioctl_time64(int fd, unsigned long req, void *arg) { return ioctl(fd, req, arg); }
int __clock_gettime64(long clk, void *tp);
int __clock_gettime64(long clk, void *tp) { return clock_gettime(clk, tp); }
int __clock_nanosleep_time64(long c, int f, const void *req, void *rem);
int __clock_nanosleep_time64(long c, int f, const void *req, void *rem) { return clock_nanosleep(c, f, req, rem); }
int __pthread_mutex_timedlock_time64(void *m, const void *t);
int __pthread_mutex_timedlock_time64(void *m, const void *t) { return pthread_mutex_timedlock(m, t); }
