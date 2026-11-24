/* libdlog stub: route all Tizen dlog output to stderr for qemu emulation */
#include <stdio.h>
#include <stdarg.h>

static void emit(int prio, const char *tag, const char *fmt, va_list ap) {
    fprintf(stderr, "[DLOG p%d %s] ", prio, tag ? tag : "?");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
}

__attribute__((visibility("default"))) int dlog_print(int prio, const char *tag, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); emit(prio, tag, fmt, ap); va_end(ap); return 0;
}
__attribute__((visibility("default"))) int dlog_print_native(int prio, const char *tag, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); emit(prio, tag, fmt, ap); va_end(ap); return 0;
}
__attribute__((visibility("default"))) int dlog_print_dotnet(int prio, const char *tag, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); emit(prio, tag, fmt, ap); va_end(ap); return 0;
}
__attribute__((visibility("default"))) int __dlog_print(int lid, int prio, const char *tag, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); emit(prio, tag, fmt, ap); va_end(ap); return 0;
}
__attribute__((visibility("default"))) int __dlog_print_force(int lid, int prio, const char *tag, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); emit(prio, tag, fmt, ap); va_end(ap); return 0;
}
__attribute__((visibility("default"))) int dlog_vprint(int prio, const char *tag, const char *fmt, va_list ap) {
    emit(prio, tag, fmt, ap); return 0;
}
__attribute__((visibility("default"))) int dlog_vprint_native(int prio, const char *tag, const char *fmt, va_list ap) {
    emit(prio, tag, fmt, ap); return 0;
}
__attribute__((visibility("default"))) int dlog_vprint_dotnet(int prio, const char *tag, const char *fmt, va_list ap) {
    emit(prio, tag, fmt, ap); return 0;
}
__attribute__((visibility("default"))) int __dlog_vprint(int lid, int prio, const char *tag, const char *fmt, va_list ap) {
    emit(prio, tag, fmt, ap); return 0;
}
__attribute__((visibility("default"))) void vlog_write(int lid, int prio, const char *tag, const char *fmt, va_list ap) {
    emit(prio, tag, fmt, ap);
}
__attribute__((visibility("default"))) int __dlog_init_backend(void) { return 0; }
__attribute__((visibility("default"))) void __dlog_fini(void) { }
__attribute__((visibility("default"))) void __dlog_fatal_assert(void) { fprintf(stderr, "[DLOG] fatal_assert\n"); }
__attribute__((visibility("default"))) int log_id_by_name(const char *n) { return 0; }
__attribute__((visibility("default"))) const char *log_name_by_id(int id) { return "apps"; }
__attribute__((visibility("default"))) const char *get_config_filename(void) { return "/dev/null"; }
__attribute__((visibility("default"))) int log_config_foreach(void *cb, void *ud) { return 0; }
__attribute__((visibility("default"))) void log_config_free(void *c) { }
__attribute__((visibility("default"))) void *log_config_get(const char *k) { return 0; }
__attribute__((visibility("default"))) void log_config_print_key(void *c) { }
__attribute__((visibility("default"))) void log_config_print_out(void *c) { }
__attribute__((visibility("default"))) int log_config_push(const char *k, const char *v) { return 0; }
__attribute__((visibility("default"))) int log_config_read(void) { return -1; }
__attribute__((visibility("default"))) int log_config_read_file(const char *f) { return -1; }
__attribute__((visibility("default"))) int log_config_remove(const char *k) { return 0; }
__attribute__((visibility("default"))) int log_config_set(const char *k, const char *v) { return 0; }
__attribute__((visibility("default"))) int log_config_write(const char *f) { return -1; }
__attribute__((visibility("default"))) int recv_file_descriptor(void) { return -1; }
__attribute__((visibility("default"))) void syslog_critical_failure(void) { }
