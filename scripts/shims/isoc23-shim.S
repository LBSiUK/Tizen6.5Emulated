/* glibc 2.38 renamed these to the ISO C23 forms and shmctl to __shmctl64;
   the tree's glibc 2.30 only has the classic names.  Tail-branch keeps the
   varargs registers intact, so behaviour matches for our callers. */
.text
.macro ALIAS new, old
.globl \new
\new:
    b \old
.endm
ALIAS __isoc23_scanf,     scanf
ALIAS __isoc23_sscanf,    sscanf
ALIAS __isoc23_fscanf,    fscanf
ALIAS __isoc23_vscanf,    vscanf
ALIAS __isoc23_vsscanf,   vsscanf
ALIAS __isoc23_vfscanf,   vfscanf
ALIAS __isoc23_strtol,    strtol
ALIAS __isoc23_strtoul,   strtoul
ALIAS __isoc23_strtoll,   strtoll
ALIAS __isoc23_strtoull,  strtoull
ALIAS __isoc23_strtoimax, strtoimax
ALIAS __isoc23_strtoumax, strtoumax
ALIAS __shmctl64,         shmctl
ALIAS __semctl64,         semctl
ALIAS __msgctl64,         msgctl
