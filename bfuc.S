#include "def.S"

.globl _start

/* set correct SYS_WRITE args for the passed ERR */
#define PRINTERR_SET_WRITE_ARGS(ERR)  \
    mov    $ERR##_MSG, %rsi          ;\
    mov    $ERR##_MSG_SIZE, %rdx     ;\
    jmp    .Lprinterr_print

/* flush wbuf, jumping to the end on error */
#define BFCOMPILE_WRITE        \
    mov    %rbx, %rdi         ;\
    mov    $wbuf, %rsi        ;\
    mov    wbufp, %rdx        ;\
    SYSCALL(SYS_WRITE)        ;\
    cmp    $0, %rax           ;\
    jg     0f                 ;\
    mov    $ERR_WRITE, %rax   ;\
    jmp    .Lcompile_loop_end ;\
    0:                        ;\
    movq    $0, wbufp

/* jump to the end on error */
#define BFPARSE_CHECK_NOMEM  \
    cmp    $ERR_NOMEM, %rax ;\
    je     .Lparse_loop_end
/* Push an OP with a value into the opvec*/
#define BFPARSE_PUSH_OP_VAL(OP) \
    mov    $OP, %rsi           ;\
    or     %rsi, %rdi          ;\
    call   opvec_push          ;\
    BFPARSE_CHECK_NOMEM        ;\
    addq   $OP##_COD_SIZE, op_offset
/* Push an OP into the opvec */
#define BFPARSE_PUSH_OP(OP)     \
    mov    $OP, %rdi           ;\
    call   opvec_push          ;\
    BFPARSE_CHECK_NOMEM        ;\
    addq   $OP##_COD_SIZE, op_offset
/* check arthopc and push an arthop if it's not 0 */
#define BFPARSE_FLUSH_ARTHOP      \
    cmpb   $0, arthopc           ;\
    je     0f                    ;\
    movzb  arthopc, %rdi         ;\
    BFPARSE_PUSH_OP_VAL(OP_ARTH) ;\
    movb   $0, arthopc           ;\
    0:
/* check movopc and push a movop if it's not 0 */
#define BFPARSE_FLUSH_MOVOP      \
    cmpl   $0, movopc           ;\
    je     0f                   ;\
    mov    movopc, %edi         ;\
    BFPARSE_PUSH_OP_VAL(OP_MOV) ;\
    movl   $0, movopc           ;\
    0:

.bss
/* Op counters */
arthopc:     .byte  0
movopc:      .int   0

/* A vector of qword OP* values,
 * allocated with brk.
 */
opvec:       .quad  0
opvec_len:   .quad  0
opvec_cap:   .quad  0

/* Current op's offset in bytes */
op_offset:   .quad  0

/* Current program break */
brk_curr:    .quad  0

/* Read buffer stuff */
rbuf:        .space RBUFSIZE
rbufp:       .quad  0
rbuflen:     .quad  0
/* Write buffer stuff */
wbuf:        .space WBUFSIZE
wbufp:       .quad  0

.data
/* elf header */
E_HEADER_DEF

/* op optcodes */
OP_SETUP_COD_DEF
OP_EXIT_COD_DEF
OP_ARTH_COD_DEF
OP_MOV_COD_DEF
OP_CMP_COD_DEF
OP_JZ_COD_DEF
OP_JNZ_COD_DEF
OP_PRINT_COD_DEF
OP_GET_COD_DEF

/* error messages */
ERR_NOMEM_MSG_DEF
ERR_WRITE_MSG_DEF
ERR_NOCLOSED_MSG_DEF
ERR_NOOPEN_MSG_DEF
ERR_NOOPS_MSG_DEF
ERR_ROPEN_MSG_DEF
ERR_WOPEN_MSG_DEF

/* output file path */
OUTPATH_DEF

.text
_start:
    /* pass argc and argv as fn args */
    pop    %rdi
    mov    %rsp, %rsi
    call   bfparse_args
    cmp    $OK, %rax
    jne    .Lexit

    mov    $OUTPATH, %rdi
    call   bfcompile_into_path

    .Lexit:
    mov    %rax, %rdi
    SYSCALL(SYS_EXIT)

/* Call bfcompile with the fd being an opened 
 * file with the provided path.
 * ARGS:
 *  null-terminated file path
 * RETURNS:
 *  OK
 *  or
 *  an ERR_* value
 */
bfcompile_into_path:
    push   %rbx

    /* open the file with
     * O_CREAT and O_WRONLY
     */
    mov    $(0x1 | 0x40), %rsi
    mov    $0755, %rdx
    SYSCALL(SYS_OPEN)
    /* check for errors */
    cmp    $0, %rax
    jge    0f
    /* print error message */
    mov    $STDERR, %rdi
    mov    $ERR_WOPEN_MSG, %rsi
    mov    $ERR_WOPEN_MSG_SIZE, %rdx
    SYSCALL(SYS_WRITE)
    /* return error value and exit */
    mov    $ERR_WRITE, %rax
    jmp    1f
    
    0:
    /* store the fd */
    mov    %rax, %rbx
    /* parse the fd */
    mov    %rbx, %rdi
    call   bfcompile
    /* restore the fd and store the return value */
    mov    %rbx, %rdi
    mov    %rax, %rbx

    /* close the file */
    SYSCALL(SYS_CLOSE)

    /* restore the return value and check for errors */
    mov    %rbx, %rax
    cmp    $OK, %rax
    je     1f
    /* print errors */
    mov    %rax, %rdi
    call   printerr

    1:
    pop    %rbx
    ret

/* Call bfparse with the fd either being stdin
 * or an opened file whose path resides in argv. 
 * ARGS:
 *  argc, argv
 * RETURNS:
 *  OK
 *  or
 *  an ERR_* value
 */
bfparse_args:
    push   %rbx

    /* read the input file path from
     * the first arg; use stdin if 
     * none were provided
     */
    cmp    $1, %rdi
    je     1f
    /* open the file */
    mov    8(%rsi), %rdi
    mov    $0x0, %rsi
    SYSCALL(SYS_OPEN)
    /* check for errors */
    cmp    $0, %rax
    jge    0f
    /* print error message */
    mov    $STDERR, %rdi
    mov    $ERR_ROPEN_MSG, %rsi
    mov    $ERR_ROPEN_MSG_SIZE, %rdx
    SYSCALL(SYS_WRITE)
    /* return error value and exit */
    mov    $ERR_READ, %rax
    jmp    3f

    0:
    /* store the fd */
    mov    %rax, %rbx
    jmp    2f
    1:
    mov    $STDIN, %rbx
    2:
    /* parse the fd */
    mov    %rbx, %rdi
    call   bfparse
    /* restore the in fd and store the return value */
    mov    %rbx, %rdi
    mov    %rax, %rbx

    /* close the file */
    SYSCALL(SYS_CLOSE)

    /* restore the return value and check for errors */
    mov    %rbx, %rax
    cmp    $OK, %rax
    je     3f
    /* print errors */
    mov    %rax, %rdi
    call   printerr

    3:
    pop    %rbx
    ret


/* Print the passed code as an error msg.
 * ARGS:
 *  ERR_* code
 * RETURNS:
 *  the passed code
 */
printerr:
    /* store the passed value */
    push   %rdi
    mov    %rdi, %rax

    mov    $STDERR, %rdi

    /* jump to the matching label */
    neg    %rax
    add    $ERR_NOMEM, %rax
    mov    .Lprinterr_jmptbl(,%rax, 4), %eax
    jmp    *%rax

    .Lprinterr_onnomem:
    PRINTERR_SET_WRITE_ARGS(ERR_NOMEM)
    .Lprinterr_onwrite:
    PRINTERR_SET_WRITE_ARGS(ERR_WRITE)
    .Lprinterr_onnoclosed:
    PRINTERR_SET_WRITE_ARGS(ERR_NOCLOSED)
    .Lprinterr_onnoopen:
    PRINTERR_SET_WRITE_ARGS(ERR_NOOPEN)
    .Lprinterr_onnoops:
    PRINTERR_SET_WRITE_ARGS(ERR_NOOPS)

    .Lprinterr_print:
    /* print the message */
    SYSCALL(SYS_WRITE)
    /* return the passed value */
    pop    %rax
    ret

    .Lprinterr_jmptbl:
    .int \
       .Lprinterr_onnomem,                      \
    .Lprinterr_onnoclosed, .Lprinterr_onnoopen, \
       .Lprinterr_onnoops,  .Lprinterr_onwrite


/* Compile the contents of the opvec
 * into an executable ELF written
 * to the provided file descriptor.
 * ARGS:
 *  file descriptor
 * RETURNS:
 *  OK
 *  or
 *  an ERR_* value
 */
bfcompile:
    /* save rbx, r12 and the stack pointer */
    push   %rbx
    push   %r12
    push   %rbp
    mov    %rsp, %rbp

    /* save the passed fd */
    mov    %rdi, %rbx

    /* check if the opvec isn't empty */
    cmpq   $0, opvec_len
    jg     0f
    mov    $ERR_NOOPS, %rax
    jmp    .Lcompile_loop_end

    0:
    /* update the txt segment's sizes */
    mov    op_offset, %rax
    mov    %rax, P_TXT_FILESZ
    mov    %rax, P_TXT_MEMSZ
    /* write the elf header */
    mov    $E_HEADER, %rsi
    mov    $wbuf, %rdi
    mov    $E_HEADER_SIZE, %rcx
    rep    movsb
    addq   $E_HEADER_SIZE, wbufp

    xor    %r12, %r12
    .Lcompile_loop:
    /* fetch the opvec entry */
    mov    opvec, %rax
    mov    (%rax, %r12, OPVEC_ENTRY_SIZE), %rax

    /* read OP's id and jump to its matching label */
    mov    %rax, %rcx
    shr    $32, %rcx
    mov    .Lcompile_jmptbl(,%rcx, 4), %ecx
    jmp    *%rcx

    .Lcompile_onexitop:
    mov    $OP_EXIT_COD, %rsi
    mov    $OP_EXIT_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onsetupop:
    mov    $OP_SETUP_COD, %rsi
    mov    $OP_SETUP_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onarthop:
    mov    %al, OP_ARTH_COD_VAL
    mov    $OP_ARTH_COD, %rsi
    mov    $OP_ARTH_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onmovop:
    mov    %eax, OP_MOV_COD_VAL
    mov    $OP_MOV_COD, %rsi
    mov    $OP_MOV_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_oncmpop:
    mov    $OP_CMP_COD, %rsi
    mov    $OP_CMP_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onjzop:
    mov    %eax, OP_JZ_COD_VAL
    mov    $OP_JZ_COD, %rsi
    mov    $OP_JZ_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onjnzop:
    mov    %eax, OP_JNZ_COD_VAL
    mov    $OP_JNZ_COD, %rsi
    mov    $OP_JNZ_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_onprintop:
    mov    $OP_PRINT_COD, %rsi
    mov    $OP_PRINT_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond
    .Lcompile_ongetop:
    mov    $OP_GET_COD, %rsi
    mov    $OP_GET_COD_SIZE, %rcx
    jmp    .Lcompile_loop_cond

    .Lcompile_loop_cond:
    /* check if there's space in wbuf */
    mov    wbufp, %rax
    add    %rcx, %rax
    cmp    $WBUFSIZE, %rcx
    jge    0f

    /* store the op bin data */
    push   %rsi
    push   %rcx
    BFCOMPILE_WRITE
    /* restore the op bin data */
    pop     %rcx
    pop     %rsi

    0:
    /* copy the op_*_bin to the wbuf */
    mov    wbufp, %rax
    lea    wbuf(%rax), %rdi
    add    %rcx, wbufp
    rep    movsb

    inc    %r12
    cmp    opvec_len, %r12
    jne    .Lcompile_loop

    .Lcompile_loop_ok:
    /* flush wbuf */ 
    BFCOMPILE_WRITE
    mov    $OK, %rax

    .Lcompile_loop_end:
    mov    %rbp, %rsp
    pop    %rbp
    pop    %r12
    pop    %rbx
    ret

    .Lcompile_jmptbl:
    .int \
    .Lcompile_onsetupop,  .Lcompile_onexitop, .Lcompile_onarthop, \
      .Lcompile_onmovop,   .Lcompile_oncmpop,   .Lcompile_onjzop, \
      .Lcompile_onjnzop, .Lcompile_onprintop,  .Lcompile_ongetop

/* Parse the provided brainfuck file
 * into an operation vector (opvec), where
 * every entry contains a type and optional value.
 * ARGS:
 *  file descriptor
 * RETURNS:
 *  OK
 *  or
 *  an ERR_* value
 */
bfparse:
    /* save rbx, r12 and the stack pointer */
    push   %rbx
    push   %r12
    push   %rbp
    mov    %rsp, %rbp

    /* save the passed fd */
    mov    %rdi, %rbx

    /* try to initialize opvec */
    call   opvec_init
    BFPARSE_CHECK_NOMEM

    /* push OP_SETUP */
    BFPARSE_PUSH_OP(OP_SETUP)
    .Lparse_loop:
    /* get char from stdin */
    mov    %rbx, %rdi
    call   getc
    /* check for errors */
    cmp    $EOF, %rax
    je     .Lparse_loop_check

    /* MS 5 bits contain the jmpdir index */ 
    mov    %rax, %rcx
    shr    $3, %rcx
    movzb  .Lparse_jmpdir(%rcx), %rcx
    /* LS 3 bits contain the jmptbl offset,
     * combining it with the read jmpdir entry
     * gets us the jmptbl index
     */
    and    $7, %rax
    mov    .Lparse_jmptbl(%rcx, %rax, 4), %eax
    jmp    *%rax

    .Lparse_onaddop:
    BFPARSE_FLUSH_MOVOP
    incb   arthopc;
    jmp    .Lparse_loop

    .Lparse_onsubop:
    BFPARSE_FLUSH_MOVOP
    decb   arthopc
    jmp    .Lparse_loop

    .Lparse_onrightop:
    BFPARSE_FLUSH_ARTHOP
    incl   movopc
    jmp    .Lparse_loop

    .Lparse_onleftop:
    BFPARSE_FLUSH_ARTHOP
    decl   movopc
    jmp    .Lparse_loop

    .Lparse_onjzop:
    BFPARSE_FLUSH_ARTHOP
    BFPARSE_FLUSH_MOVOP
    /* push cmpop just in case */
    BFPARSE_PUSH_OP(OP_CMP)
    /* store the jzop's opvec index */
    push   opvec_len
    /* push an empty jzop and store the offset after it */
    BFPARSE_PUSH_OP(OP_JZ)
    push   op_offset
    jmp    .Lparse_loop

    .Lparse_onjnzop:
    BFPARSE_FLUSH_ARTHOP
    BFPARSE_FLUSH_MOVOP
    /* check if there's a matching jzop */
    cmp    %rsp, %rbp
    je     1f

    /* push cmpop just in case */
    BFPARSE_PUSH_OP(OP_CMP)

    /* get the offset after the last jzop */
    pop    %r12
    /* push a jnzop containing the relative 
     * offset from after itself to the location 
     * after the last jzop
     */
    mov    %r12, %rdi
    sub    op_offset, %edi
    sub    $OP_JNZ_COD_SIZE, %edi
    BFPARSE_PUSH_OP_VAL(OP_JNZ)

    /* calculate the last jzop's address */
    pop    %rdi
    mov    opvec, %rax
    lea    (%rax, %rdi, OPVEC_ENTRY_SIZE), %rdi

    /* put the relative offset from after the last jzop
     * to the location after the current jznop
     * in the last jzop entry
     */
    mov    op_offset, %rax
    sub    %r12, %rax
    mov    %eax, (%rdi)
    jmp    .Lparse_loop
    1:
    mov    $ERR_NOOPEN , %rax
    jmp    .Lparse_loop_end

    .Lparse_onprintop:
    BFPARSE_FLUSH_ARTHOP
    BFPARSE_FLUSH_MOVOP
    BFPARSE_PUSH_OP(OP_PRINT)
    jmp    .Lparse_loop

    .Lparse_ongetop:
    BFPARSE_FLUSH_ARTHOP
    BFPARSE_FLUSH_MOVOP
    BFPARSE_PUSH_OP(OP_GET)
    jmp    .Lparse_loop

    .Lparse_loop_check:
    /* check if every jzop has been closed */
    cmp    %rsp, %rbp
    je     .Lparse_loop_ok
    mov    $ERR_NOCLOSED, %rax
    jmp    .Lparse_loop_end
    .Lparse_loop_ok:
    /* flush leftover ops */
    BFPARSE_FLUSH_ARTHOP
    BFPARSE_FLUSH_MOVOP
    /* push the OP_EXIT */
    BFPARSE_PUSH_OP(OP_EXIT)
    /* try to return OK */
    mov    $OK, %rax
    .Lparse_loop_end:
    /* restore the stack pointer and rbx */
    mov    %rbp, %rsp
    pop    %rbp
    pop    %r12
    pop    %rbx
    ret

    .Lparse_jmpdir:
    .byte  0,  0,  0,  0,  0, 32, \
           0, 64,  0,  0,  0, 96
    .skip  52
    .Lparse_jmptbl:
    .int \
        .Lparse_loop,    .Lparse_loop,      .Lparse_loop,    .Lparse_loop, \
        .Lparse_loop,    .Lparse_loop,      .Lparse_loop,    .Lparse_loop, \
        .Lparse_loop,    .Lparse_loop,      .Lparse_loop, .Lparse_onaddop, \
     .Lparse_ongetop, .Lparse_onsubop, .Lparse_onprintop,    .Lparse_loop, \
        .Lparse_loop,    .Lparse_loop,      .Lparse_loop,    .Lparse_loop, \
    .Lparse_onleftop,    .Lparse_loop, .Lparse_onrightop,    .Lparse_loop, \
        .Lparse_loop,    .Lparse_loop,      .Lparse_loop,  .Lparse_onjzop, \
        .Lparse_loop, .Lparse_onjnzop,      .Lparse_loop,    .Lparse_loop

/* Try to allocate the opvec.
 * RETURNS:
 *  OK
 *  or
 *  ERR_NOMEM
 */
opvec_init:
    call   brk_init

    /* try to alloc OPVEC_INIT_CAP bytes */
    mov    $OPVEC_INIT_CAP, %rdi
    call   sbrk
    /* check for errors */
    cmp    $ERR_NOMEM, %rax
    je     0f

    /* update opvec* globals on success */
    mov    %rax, (opvec)
    movq   $OPVEC_INIT_CAP, (opvec_cap)
    /* and return OK */
    mov    $OK, %rax

    0:
    ret

/* Push an entry into the opvec.
 * ARGS:
 *  opv_entry
 * RETURNS:
 *  OK
 *  or
 *  ERR_NOMEM 
 */
opvec_push:
    push   %rbx

    /* check if (opvec_len * OPVEC_ENTRY_SIZE) 
     * reached opvec_cap 
     */
    mov    opvec_len, %rbx
    lea    (,%rbx, OPVEC_ENTRY_SIZE), %rbx
    cmp    opvec_cap, %rbx
    jne    0f

    push   %rdi

    /* alloc opvec_cap more memory */
    mov    opvec_cap, %rdi
    call   sbrk
    /* check for errors */
    cmp    $ERR_NOMEM, %rax
    je     1f

    /* double opvec_cap on success */
    shlq   $1, opvec_cap

    pop    %rdi

    /* store the entry at opvec[opvec_len] */
    0:
    add    opvec, %rbx
    mov    %rdi, (%rbx)
    /* update opvec_len */
    incq   opvec_len
    /* and return OK */
    mov    $OK, %rax

    1:
    pop    %rbx
    ret

/* Set up brk_curr */
brk_init:
    mov    $0, %rdi
    SYSCALL(SYS_BRK)
    mov    %rax, brk_curr
    ret

/* Extends brk_curr by increment bytes.
 * ARGS: 
 *  increment
 * RETURNS: rax: 
 *  previous brk_curr
 *  or
 *  ERR_NOMEM
 */
sbrk:
    push   %rbx

    /* store prev brk_curr */
    mov    brk_curr, %rbx

    /* extend bretrk */
    add    %rbx, %rdi
    SYSCALL(SYS_BRK)
    /* check for errors */
    cmp    $0, %rax
    jl     1f

    /* update brk_curr 
     * and return prev brk on success 
     */
    0:
    mov    %rax, brk_curr
    mov    %rbx, %rax
    jmp    2f

    /* ERR_NOMEM on error */
    1:
    mov    $ERR_NOMEM, %rax

    /* cleanup & return */
    2:
    pop    %rbx
    ret

/* Buffered single byte reading from
 * the specified file.
 * ARGS:
 *  file descriptor
 * RETURNS:
 *  char from fd
 *  or
 *  EOF on error or end of file
 */
getc:
    push   %rbx

    /* check if rbuf is filled */
    mov    rbufp, %rbx
    cmp    %rbx, rbuflen
    jne    0f
    
    /* try to read RBUFSIZE bytes */
    mov    $rbuf, %rsi
    mov    $RBUFSIZE, %rdx
    SYSCALL(SYS_READ)
    /* check for errors */
    cmp    $0, %rax
    jle    1f
    
    /* reset rbufp & rbuflen */
    movq   $0, rbufp
    xor    %rbx, %rbx
    mov    %rax, rbuflen

    /* return char at rbufp */
    0:
    movzb  rbuf(%rbx), %rax
    incq   rbufp
    jmp    2f

    /* return EOF on error */
    1:
    mov    $EOF, %rax

    /* cleanup & return */
    2:
    pop    %rbx
    ret
