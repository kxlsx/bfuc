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

#define ERR_NOMEM_MSG \
err_nomem_msg: \
    .ascii "Failed allocating memory.\n" ;\
.Lerr_nomem_msg_end:
#define ERR_NOMEM_MSG_SIZE \
    (.Lerr_nomem_msg_end - err_nomem_msg)

#define ERR_WRITE_MSG \
err_write_msg: \
    .ascii "Failed writing to file.\n" ;\
.Lerr_write_msg_end:
#define ERR_WRITE_MSG_SIZE \
    (.Lerr_write_msg_end - err_write_msg)

#define ERR_NOCLOSED_MSG \
err_noclosed_msg: \
    .ascii "Parse error: Unclosed ']'.\n" ;\
.Lerr_noclosed_msg_end:
#define ERR_NOCLOSED_MSG_SIZE \
    (.Lerr_noclosed_msg_end - err_noclosed_msg)

#define ERR_NOOPEN_MSG \
err_noopen_msg: \
    .ascii "Parse error: Unopened '['.\n" ;\
.Lerr_noopen_msg_end:
#define ERR_NOOPEN_MSG_SIZE \
    (.Lerr_noopen_msg_end - err_noopen_msg)

#define ERR_NOOPS_MSG \
err_noops_msg: \
    .ascii "No instructions; something has gone very wrong.\n" ;\
.Lerr_noops_msg_end:
#define ERR_NOOPS_MSG_SIZE \
    (.Lerr_noops_msg_end - err_noops_msg)

#define ERR_ROPEN_MSG \
err_ropen_msg: \
    .ascii "Failed opening input file.\n" ;\
.Lerr_ropen_msg:
#define ERR_ROPEN_MSG_SIZE \
    (.Lerr_ropen_msg - err_ropen_msg)

#define ERR_WOPEN_MSG \
err_wopen_msg: \
    .ascii "Failed creating output file.\n" ;\
.Lerr_wopen_msg:
#define ERR_WOPEN_MSG_SIZE \
    (.Lerr_wopen_msg - err_wopen_msg)

/* output file path definiton */
#define OUTPATH \
    outpath: .ascii "a.out"

/* buffer sizes */
#define RBUFSIZE 4096
#define WBUFSIZE 7980

/* elf header definitions */
#define E_BASEADDR  0x400000
#define E_ALIGN     0x1000
#define E_BSS_LEN   8 * E_ALIGN
#define E_BSSADDR   E_BASEADDR + 0xb0
#define E_TXTADDR   E_BSSADDR  + E_BSS_LEN
#define E_UNDEF     0x0
#define E_HEADER       \
e_header:              \
e_ident:               \
    .byte   0x7f      ;\
    .ascii  "ELF"     ;\
    .byte   0x2       ;\
    .byte   0x1       ;\
    .byte   0x1       ;\
    .byte   0x0       ;\
    .byte   E_UNDEF   ;\
    .zero   7         ;\
e_type:                \
    .word   0x2       ;\
e_machine:             \
    .word   0x3e      ;\
e_version:             \
    .int    0x1       ;\
e_entry:               \
    .quad   E_TXTADDR ;\
e_phoff:               \
    .quad   0x40      ;\
e_shoff:               \
    .quad   E_UNDEF   ;\
e_flags:               \
    .int    E_UNDEF   ;\
e_ehsize:              \
    .word   0x40      ;\
e_phentsize:           \
    .word   0x38      ;\
e_phnum:               \
    .word   0x2       ;\
e_shentsize:           \
    .word   E_UNDEF   ;\
e_shnum:               \
    .word   E_UNDEF   ;\
e_shstrndx:            \
    .word   E_UNDEF ;\
p_bss_header:          \
p_bss_type:            \
    .int    0x1       ;\
p_bss_flags:           \
    .int    0x6       ;\
p_bss_offset:          \
    .quad   0xb0      ;\
p_bss_vaddr:           \
    .quad   E_BSSADDR ;\
p_bss_paddr:           \
    .quad   E_UNDEF   ;\
p_bss_filesz:          \
    .quad   0x0       ;\
p_bss_memsz:           \
    .quad   E_BSS_LEN ;\
p_bss_align:           \
    .quad   E_ALIGN   ;\
p_txt_header:          \
p_txt_type:            \
    .int    0x1       ;\
p_txt_flags:           \
    .int    0x5       ;\
p_txt_offset:          \
    .quad   0xb0      ;\
p_txt_vaddr:           \
    .quad   E_TXTADDR ;\
p_txt_paddr:           \
    .quad   E_UNDEF   ;\
p_txt_filesz:          \
    .quad   E_UNDEF   ;\
p_txt_memsz:           \
    .quad   E_UNDEF   ;\
p_txt_align:           \
    .quad   E_ALIGN   ;\
.Le_header_end:  
#define __E_HEADER_SIZE()   (.Le_header_end - e_header)
#define E_HEADER_SIZE __E_HEADER_SIZE()

/* opvec and op stuff */
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

/* mov $E_BSSADDR, %rbx
 * mov $1, %rdx
 */
#define OP_SETUP_BIN \
op_setup_bin: \
    .byte 0x48, 0xc7, 0xc3; .int E_BSSADDR; \
    .byte 0x48, 0xc7, 0xc2; .int 0x1;       \
.Lop_setup_bin_end:
#define OP_SETUP_BIN_SIZE (.Lop_setup_bin_end - op_setup_bin)

/* mov (%rbx), %rdi 
 * mov $SYS_EXIT, %rax
 */
#define OP_EXIT_BIN  \
op_exit_bin:  \
    .byte 0x48, 0x8b, 0x3b;                \
    .byte 0x48, 0xc7, 0xc0; .int SYS_EXIT; \
    .byte 0x0f, 0x05;                      \
.Lop_exit_bin_end:
#define OP_EXIT_BIN_SIZE (.Lop_exit_bin_end - op_exit_bin)

/* add $arthop_bin_val, (%rbx) */
#define OP_ARTH_BIN  \
op_arth_bin:  \
    .byte 0x80, 0x03;       op_arth_bin_val: .byte 0x0; \
.Lop_arth_bin_end:
#define OP_ARTH_BIN_SIZE  (.Lop_arth_bin_end - op_arth_bin)

/* lea $movop_bin_val(%rbx), %rbx */
#define OP_MOV_BIN   \
op_mov_bin:   \
    .byte 0x48, 0x8d, 0x9b; op_mov_bin_val:  .int 0x0;  \
.Lop_mov_bin_end:
#define OP_MOV_BIN_SIZE (.Lop_mov_bin_end - op_mov_bin)

/* testb 0xff, (%rbx) */
#define OP_CMP_BIN   \
op_cmp_bin:   \
    .byte 0xf6, 0x03, 0xff; \
.Lop_cmp_bin_end:
#define OP_CMP_BIN_SIZE (.Lop_cmp_bin_end - op_cmp_bin)

/* jnz $op_jz_bin_val */
#define OP_JZ_BIN    \
op_jz_bin:    \
    .byte 0x0f, 0x84;       op_jz_bin_val:   .int 0x0;  \
.Lop_jz_bin_end:
#define __OP_JZ_BIN_SIZE() (.Lop_jz_bin_end - op_jz_bin)
#define OP_JZ_BIN_SIZE __OP_JZ_BIN_SIZE()

/* jnz   $op_jnz_bin_val */
#define OP_JNZ_BIN   \
op_jnz_bin:   \
    .byte 0x0f, 0x85;       op_jnz_bin_val:   .int 0x0; \
.Lop_jnz_bin_end:
#define OP_JNZ_BIN_SIZE (.Lop_jnz_bin_end - op_jnz_bin)

/* mov $0x0, %rdi
 * mov %rbx, %rsi
 * mov $SYS_WRITE, %rax
 * syscall
 */
#define OP_PRINT_BIN \
op_print_bin:  \
    .byte 0x48, 0xc7, 0xc7; .int STDOUT;    \
    .byte 0x48, 0x89, 0xde;                 \
    .byte 0x48, 0xc7, 0xc0; .int SYS_WRITE; \
    .byte 0x0f, 0x05;                       \
.Lop_print_bin_end:
#define OP_PRINT_BIN_SIZE (.Lop_print_bin_end - op_print_bin)

/* mov $0x1, %rdi
 * mov %rbx, %rsi`
 * mov $SYS_READ, %rax
 * syscall
 */
#define OP_GET_BIN   \
op_get_bin:    \
    .byte 0x48, 0xc7, 0xc7; .int STDIN;    \
    .byte 0x48, 0x89, 0xde;                \
    .byte 0x48, 0xc7, 0xc0; .int SYS_READ; \
    .byte 0x0f, 0x05;                      \
.Lop_get_bin_end:
#define OP_GET_BIN_SIZE (.Lop_get_bin_end - op_get_bin)
