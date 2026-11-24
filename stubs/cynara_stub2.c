int cynara_initialize(void **h, const void *c) { (void)h; (void)c; return 0; }
int cynara_check(void *h, const char *a, const char *b, const char *c, const char *d) { (void)h;(void)a;(void)b;(void)c;(void)d; return 2; }
void cynara_finish(void *h) { (void)h; }
int cynara_session_initialize(void **h, int a, const char *b, const char *c, const char *d, const char *e) { (void)h;(void)a;(void)b;(void)c;(void)d;(void)e; return 0; }
int cynara_session_check(void *h, int a, const char *b, const char *c) { (void)h;(void)a;(void)b;(void)c; return 2; }
void cynara_session_finish(void *h) { (void)h; }
int __log_level = 4;
__asm(".globl _Z17cynara_dlog_printiPKcz\n_Z17cynara_dlog_printiPKcz:\n mov r0, #0\n bx lr\n");
__asm(".globl _Z17cynara_dlog_printePKcz\n_Z17cynara_dlog_printePKcz:\n mov r0, #0\n bx lr\n");
__asm(".globl _Z17cynara_dlog_printwPKcz\n_Z17cynara_dlog_printwPKcz:\n mov r0, #0\n bx lr\n");
__asm(".globl _Z17cynara_dlog_printdPKcz\n_Z17cynara_dlog_printdPKcz:\n mov r0, #0\n bx lr\n");
static const char sess[] = "emulated";
int cynara_session_from_pid(int pid, char **session) { (void)pid; if (session) *session = (char*)sess; return 0; }
void cynara_session_free(char *session) { (void)session; }
