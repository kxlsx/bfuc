#define LABELIZE(LABELM) LABELM##:

#define STDIN  0
#define STDOUT 1
#define STDERR 2

#define SYS_READ   0
#define SYS_WRITE  1
#define SYS_OPEN   2
#define SYS_CLOSE  3
#define SYS_BRK   12
#define SYS_EXIT  60
#define SYSCALL(SYS_N)   \
    mov    $SYS_N, %rax ;\
    syscall

/* error codes and messages */
#define OK            0
#define EOF          -1
#define ERR_NOMEM    -1
#define ERR_NOCLOSED -2
#define ERR_NOOPEN   -3
#define ERR_NOOPS    -4
#define ERR_WRITE    -5
#define ERR_READ     -6

#define ERR_NOMEM_MSG .LERR_NOMEM_MSG
#define ERR_NOMEM_MSG_DEF \
LABELIZE(ERR_NOMEM_MSG) \
    .ascii "Failed allocating memory.\n" ;\
.LERR_NOMEM_MSG_END:
#define ERR_NOMEM_MSG_SIZE \
    (.LERR_NOMEM_MSG_END - ERR_NOMEM_MSG)

#define ERR_WRITE_MSG .LERR_WRITE_MSG
#define ERR_WRITE_MSG_DEF \
LABELIZE(ERR_WRITE_MSG) \
    .ascii "Failed writing to file.\n" ;\
.LERR_WRITE_MSG_END:
#define ERR_WRITE_MSG_SIZE \
    (.LERR_WRITE_MSG_END - ERR_WRITE_MSG)

#define ERR_NOCLOSED_MSG .LERR_NOCLOSED_MSG
#define ERR_NOCLOSED_MSG_DEF \
LABELIZE(ERR_NOCLOSED_MSG) \
    .ascii "Parse error: Unclosed ']'.\n" ;\
.LERR_NOCLOSED_MSG_END:
#define ERR_NOCLOSED_MSG_SIZE \
    (.LERR_NOCLOSED_MSG_END - ERR_NOCLOSED_MSG)

#define ERR_NOOPEN_MSG .LERR_NOOPEN_MSG
#define ERR_NOOPEN_MSG_DEF \
LABELIZE(ERR_NOOPEN_MSG) \
    .ascii "Parse error: Unopened '['.\n" ;\
.LERR_NOOPEN_MSG_END:
#define ERR_NOOPEN_MSG_SIZE \
    (.LERR_NOOPEN_MSG_END - ERR_NOOPEN_MSG)

#define ERR_NOOPS_MSG .LERR_NOOPS_MSG
#define ERR_NOOPS_MSG_DEF \
LABELIZE(ERR_NOOPS_MSG) \
    .ascii "No instructions; something has gone very wrong.\n" ;\
.LERR_NOOPS_MSG_END:
#define ERR_NOOPS_MSG_SIZE \
    (.LERR_NOOPS_MSG_END - ERR_NOOPS_MSG)

#define ERR_ROPEN_MSG .LERR_ROPEN_MSG
#define ERR_ROPEN_MSG_DEF \
LABELIZE(ERR_ROPEN_MSG) \
    .ascii "Failed opening input file.\n" ;\
.LERR_ROPEN_MSG_END:
#define ERR_ROPEN_MSG_SIZE \
    (.LERR_ROPEN_MSG_END - ERR_ROPEN_MSG)

#define ERR_WOPEN_MSG .LERR_WOPEN_MSG
#define ERR_WOPEN_MSG_DEF \
LABELIZE(ERR_WOPEN_MSG) \
    .ascii "Failed creating output file.\n" ;\
.LERR_WOPEN_MSG_END:
#define ERR_WOPEN_MSG_SIZE \
    (.LERR_WOPEN_MSG_END - ERR_WOPEN_MSG)

/* output file path definiton */
#define OUTPATH .LOUTPATH
#define OUTPATH_DEF \
    LABELIZE(OUTPATH) .ascii "a.out"

/* buffer sizes */
#define RBUFSIZE 4096
#define WBUFSIZE 7980

/* elf header definitions */
#define E_BASEADDR  0x400000
#define E_ALIGN     0x1000
#define E_BSS_LEN   8 * E_ALIGN
#define E_BSSADDR   E_BASEADDR + 0x40 + 0x38 * 2
#define E_TXTADDR   E_BSSADDR  + E_BSS_LEN
#define E_UNDEF     0x0

#define E_HEADER     .LE_HEADER
#define P_TXT_FILESZ .LP_TXT_FILESZ
#define P_TXT_MEMSZ  .LP_TXT_MEMSZ
#define E_HEADER_DEF   \
LABELIZE(E_HEADER)     \
/* E_IDENT */          \
    .byte   0x7f      ;\
    .ascii  "ELF"     ;\
    .byte   0x2       ;\
    .byte   0x1       ;\
    .byte   0x1       ;\
    .byte   0x0       ;\
    .byte   E_UNDEF   ;\
    .zero   7         ;\
/* E_TYPE */           \
    .word   0x2       ;\
/* E_MACHINE */        \
    .word   0x3e      ;\
/* E_VERSION */        \
    .int    0x1       ;\
/* E_ENTRY */          \
    .quad   E_TXTADDR ;\
/* E_PHOFF */          \
    .quad   0x40      ;\
/* E_SHOFF */          \
    .quad   E_UNDEF   ;\
/* E_FLAGS */          \
    .int    E_UNDEF   ;\
/* E_EHSIZE */         \
    .word   0x40      ;\
/* E_PHENTSIZE */      \
    .word   0x38      ;\
/* E_PHNUM */          \
    .word   0x2       ;\
/* E_SHENTSIZE */      \
    .word   E_UNDEF   ;\
/* E_SHNUM */          \
    .word   E_UNDEF   ;\
/* E_SHSTRNDX */       \
    .word   E_UNDEF   ;\
/* P_BSS_HEADER */     \
/* P_BSS_TYPE */       \
    .int    0x1       ;\
/* P_BSS_FLAGS */      \
    .int    0x6       ;\
/* P_BSS_OFFSET */     \
    .quad   0xb0      ;\
/* P_BSS_VADDR */      \
    .quad   E_BSSADDR ;\
/* P_BSS_PADDR */      \
    .quad   E_UNDEF   ;\
/* P_BSS_FILESZ */     \
    .quad   0x0       ;\
/* P_BSS_MEMSZ */      \
    .quad   E_BSS_LEN ;\
/* P_BSS_ALIGN */      \
    .quad   E_ALIGN   ;\
/* P_TXT_HEADER */     \
/* P_TXT_TYPE */       \
    .int    0x1       ;\
/* P_TXT_FLAGS */      \
    .int    0x5       ;\
/* P_TXT_OFFSET */     \
    .quad   0xb0      ;\
/* P_TXT_VADDR */      \
    .quad   E_TXTADDR ;\
/* P_TXT_PADDR */      \
    .quad   E_UNDEF   ;\
LABELIZE(P_TXT_FILESZ) \
    .quad   E_UNDEF   ;\
LABELIZE(P_TXT_MEMSZ)  \
    .quad   E_UNDEF   ;\
/* P_TXT_ALIGN */      \
    .quad   E_ALIGN   ;\
.LE_HEADER_END:
#define E_HEADER_SIZE (.LE_HEADER_END - E_HEADER)

/* opvec sizes */
#define OPVEC_ENTRY_SIZE 8
#define OPVEC_INIT_CAP   (1024 * OPVEC_ENTRY_SIZE)

/* An op's id's located in the most-singnificant dword */
#define OP_SETUP 0x0000000000
#define OP_EXIT  0x0100000000
#define OP_ARTH  0x0200000000
#define OP_MOV   0x0300000000
#define OP_CMP   0x0400000000
#define OP_JZ    0x0500000000
#define OP_JNZ   0x0600000000
#define OP_PRINT 0x0700000000
#define OP_GET   0x0800000000


/* op machine code translation definitions */
/* temporary dword and byte op values */
#define OP_VAL_DWTMP 0xaaaaaa
#define OP_VAL_BTMP  0xaa

#define OP_SETUP_COD .LOP_SETUP_COD
#define OP_SETUP_COD_DEF     \
LABELIZE(OP_SETUP_COD)       \
    mov    $E_BSSADDR, %rbx ;\
    mov    $1, %rdx         ;\
.LOP_SETUP_COD_END:
#define OP_SETUP_COD_SIZE (.LOP_SETUP_COD_END - OP_SETUP_COD)

#define OP_EXIT_COD .LOP_EXIT_COD
#define OP_EXIT_COD_DEF     \
LABELIZE(OP_EXIT_COD)       \
    mov    (%rbx), %rdi    ;\
    mov    $SYS_EXIT, %rax ;\
    syscall                ;\
.LOP_EXIT_COD_END:
#define OP_EXIT_COD_SIZE (.LOP_EXIT_COD_END - OP_EXIT_COD)

#define OP_ARTH_COD     .LOP_ARTH_COD
#define OP_ARTH_COD_VAL (.LOP_ARTH_COD + 2)
#define OP_ARTH_COD_DEF          \
LABELIZE(OP_ARTH_COD)            \
    addb   $OP_VAL_BTMP, (%rbx) ;\
.LOP_ARTH_COD_END:
#define OP_ARTH_COD_SIZE (.LOP_ARTH_COD_END - OP_ARTH_COD)

#define OP_MOV_COD     .LOP_MOV_COD
#define OP_MOV_COD_VAL (.LOP_MOV_COD + 3)
#define OP_MOV_COD_DEF               \
LABELIZE(OP_MOV_COD)                 \
    lea    OP_VAL_DWTMP(%rbx), %rbx ;\
.LOP_MOV_COD_END:
#define OP_MOV_COD_SIZE (.LOP_MOV_COD_END - OP_MOV_COD)

#define OP_CMP_COD .LOP_CMP_COD
#define OP_CMP_COD_DEF    \
LABELIZE(OP_CMP_COD)      \
    testb  $0xff, (%rbx) ;\
.LOP_CMP_COD_END:
#define OP_CMP_COD_SIZE (.LOP_CMP_COD_END - OP_CMP_COD)

#define OP_JZ_COD     .LOP_JZ_COD
#define OP_JZ_COD_VAL (.LOP_JZ_COD + 2)
#define OP_JZ_COD_DEF    \
LABELIZE(OP_JZ_COD)      \
    jz     OP_VAL_DWTMP ;\
.LOP_JZ_COD_END:
#define OP_JZ_COD_SIZE (.LOP_JZ_COD_END - OP_JZ_COD)

#define OP_JNZ_COD     .LOP_JNZ_COD
#define OP_JNZ_COD_VAL (.LOP_JNZ_COD + 2)
#define OP_JNZ_COD_DEF    \
LABELIZE(OP_JNZ_COD)      \
    jnz     OP_VAL_DWTMP ;\
.LOP_JNZ_COD_END:
#define OP_JNZ_COD_SIZE (.LOP_JNZ_COD_END - OP_JNZ_COD)

#define OP_PRINT_COD .LOP_PRINT_COD
#define OP_PRINT_COD_DEF     \
LABELIZE(OP_PRINT_COD)       \
    mov    $STDOUT, %rdi    ;\
    mov    %rbx, %rsi       ;\
    mov    $SYS_WRITE, %rax ;\
    syscall                 ;\
.LOP_PRINT_COD_END:
#define OP_PRINT_COD_SIZE (.LOP_PRINT_COD_END - OP_PRINT_COD)

#define OP_GET_COD .LOP_GET_COD
#define OP_GET_COD_DEF      \
LABELIZE(OP_GET_COD)        \
    mov    $STDIN, %rdi    ;\
    mov    %rbx, %rsi      ;\
    mov    $SYS_READ, %rax ;\
    syscall                ;\
.LOP_GET_COD_END:
#define OP_GET_COD_SIZE (.LOP_GET_COD_END - OP_GET_COD)
