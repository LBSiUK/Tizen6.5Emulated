/* Stand-in for libstdc++'s std::__glibcxx_assert_fail (gcc 11+).
   The TV tree ships libstdc++ 9 (GLIBCXX_3.4.27); mesa 21.3.9's
   swrast_dri.so was built against newer headers and references this. */
void abort(void);
void __glibcxx_assert_fail_stub(const char *file, int line, const char *func,
                                const char *cond)
    __asm__("_ZSt21__glibcxx_assert_failPKciS0_S0_");
void __glibcxx_assert_fail_stub(const char *file, int line, const char *func,
                                const char *cond)
{
    (void)file; (void)line; (void)func; (void)cond;
    abort();
}
