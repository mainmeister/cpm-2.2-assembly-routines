 ; =============================================================================
; DEMO-v14.ASM - CP/M 2.2 Shell with Command Line Parsing & VT100 Support
; Demonstrates CONTROL-v14.MAC macros and CPM22LIB-v14.ASM function library.
;
; Commands: DIR, TYPE, DEL, INFO, IO, SETCON, SETLST, FPTEST, BCDTEST, FIXTEST,
;           CRCTEST, CRCFILE, UARTTEST, INT32TEST, INT64TEST, MEMTEST, STRTEST,
;           ARGS, VT100, EXIT
; =============================================================================

    INCLUDE CONTROL-v14.MAC

    ORG     0100H

START:
    LXI     SP, STACK

    ; Auto-parse command line arguments on startup
    ARG_PARSE

    ; Print Banner
    LXI     HL, MSG_BANNER
    CALL    PRSTR
    CALL    PRNL

SHELL_LOOP:
    ; Print Prompt
    CALL    F_GETDRV_CALL
    ADI     'A'
    CALL    COUT
    LXI     HL, MSG_PROMPT
    CALL    PRSTR

    ; Read command line into buffer
    LXI     HL, CMD_BUF
    MVI     A, 60
    CALL    GETLINE

    MOV     A, M
    ORA     A
    JZ      SHELL_LOOP

    ; Parse First Token (Command Name)
    CALL    TOKENIZE
    SHLD    ARG1_PTR
    SDED    ARG2_PTR

    ; Command 1: "DIR"
    LHLD    ARG1_PTR
    LXI     DE, CMD_DIR
    CALL    STRCMP
    IF_ZERO 1
        CALL    DO_DIR
        JMP     SHELL_LOOP
    ENDIF_BL 1

    ; Command 2: "TYPE"
    LHLD    ARG1_PTR
    LXI     DE, CMD_TYPE
    CALL    STRCMP
    IF_ZERO 2
        CALL    DO_TYPE
        JMP     SHELL_LOOP
    ENDIF_BL 2

    ; Command 3: "DEL"
    LHLD    ARG1_PTR
    LXI     DE, CMD_DEL
    CALL    STRCMP
    IF_ZERO 3
        CALL    DO_DEL
        JMP     SHELL_LOOP
    ENDIF_BL 3

    ; Command 4: "INFO"
    LHLD    ARG1_PTR
    LXI     DE, CMD_INFO
    CALL    STRCMP
    IF_ZERO 4
        CALL    PR_DRIVE_INFO
        JMP     SHELL_LOOP
    ENDIF_BL 4

    ; Command 5: "IO"
    LHLD    ARG1_PTR
    LXI     DE, CMD_IO
    CALL    STRCMP
    IF_ZERO 5
        CALL    PR_IOBYTE
        JMP     SHELL_LOOP
    ENDIF_BL 5

    ; Command 6: "ARGS" (NEW in v13: Command Line Argument Parser Demo)
    LHLD    ARG1_PTR
    LXI     DE, CMD_ARGS
    CALL    STRCMP
    IF_ZERO 6
        CALL    PR_ARGS
        JMP     SHELL_LOOP
    ENDIF_BL 6

    ; Command 7: "VT100" (NEW in v13: VT100 Terminal & ANSI Sequences Demo)
    LHLD    ARG1_PTR
    LXI     DE, CMD_VT100
    CALL    STRCMP
    IF_ZERO 7
        CALL    DO_VT100
        JMP     SHELL_LOOP
    ENDIF_BL 7

    ; Command 8: "FPTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_FPTEST
    CALL    STRCMP
    IF_ZERO 8
        CALL    DO_FPTEST
        JMP     SHELL_LOOP
    ENDIF_BL 8

    ; Command 9: "BCDTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_BCDTEST
    CALL    STRCMP
    IF_ZERO 9
        CALL    DO_BCDTEST
        JMP     SHELL_LOOP
    ENDIF_BL 9

    ; Command 10: "FIXTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_FIXTEST
    CALL    STRCMP
    IF_ZERO 10
        CALL    DO_FIXTEST
        JMP     SHELL_LOOP
    ENDIF_BL 10

    ; Command 11: "CRCTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_CRCTEST
    CALL    STRCMP
    IF_ZERO 11
        CALL    DO_CRCTEST
        JMP     SHELL_LOOP
    ENDIF_BL 11

    ; Command 12: "INT32TEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_INT32TEST
    CALL    STRCMP
    IF_ZERO 12
        CALL    DO_INT32TEST
        JMP     SHELL_LOOP
    ENDIF_BL 12

    ; Command 13: "INT64TEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_INT64TEST
    CALL    STRCMP
    IF_ZERO 13
        CALL    DO_INT64TEST
        JMP     SHELL_LOOP
    ENDIF_BL 13

    ; Command 14: "MEMTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_MEMTEST
    CALL    STRCMP
    IF_ZERO 14
        CALL    DO_MEMTEST
        JMP     SHELL_LOOP
    ENDIF_BL 14

    ; Command 15: "STRTEST"
    LHLD    ARG1_PTR
    LXI     DE, CMD_STRTEST
    CALL    STRCMP
    IF_ZERO 15
        CALL    DO_STRTEST
        JMP     SHELL_LOOP
    ENDIF_BL 15

    ; Command 16: "EXIT"
    
    ; Command Match: "ASK" (NEW in v14: Prompt & Read Line Test)
    LHLD    ARG1_PTR
    LXI     DE, CMD_ASK
    CALL    STRCMP
    IF_ZERO 101
        CALL    DO_ASK
        JMP     SHELL_LOOP
    ENDIF_BL 101
LHLD    ARG1_PTR
    LXI     DE, CMD_EXIT
    CALL    STRCMP
    IF_ZERO 16
        LXI     HL, MSG_EXIT
        CALL    PRSTR
        CALL    PRNL
        JMP     WBOOT
    ENDIF_BL 16

    ; Unknown Command
    LXI     HL, MSG_UNKNOWN
    CALL    PRSTR
    CALL    PRNL
    JMP     SHELL_LOOP


; -----------------------------------------------------------------------------
; VT100 TERMINAL DEMONSTRATION ROUTINE (v13)
; -----------------------------------------------------------------------------
DO_VT100:
    ; 1. Clear Screen
    VT_CLS_MEM

    ; 2. Draw a decorative colored VT100 box
    VT_COLOR 3, 4       ; Yellow text (3) on Blue background (4)
    VT_DRAW_BOX 3, 10, 10, 50

    ; 3. Position cursor inside box and print bold heading
    VT_GOTO_XY 5, 15
    VT_ATTR 1           ; Bold
    LXI HL, MSG_VT_TITLE
    CALL PRSTR

    ; 4. Position cursor for reverse video status
    VT_GOTO_XY 7, 15
    VT_ATTR 7           ; Reverse Video
    LXI HL, MSG_VT_STATUS
    CALL PRSTR

    ; 5. Move cursor below box and reset attributes
    VT_GOTO_XY 15, 1
    VT_ATTR 0           ; Reset normal text
    LXI HL, MSG_VT_DONE
    CALL PRSTR
    CALL PRNL
    RET


; -----------------------------------------------------------------------------
; OTHER DEMONSTRATION ROUTINES
; -----------------------------------------------------------------------------
DO_STRTEST:
    LXI     HL, MSG_STR_HEADER
    CALL    PRSTR
    CALL    PRNL

    LXI     HL, MSG_STR_HAYSTACK
    CALL    PRSTR
    CALL    PRNL

    STRSTR_MEM MSG_STR_HAYSTACK, STR_NEEDLE1
    IF_ZERO 201
        LXI HL, MSG_STR_FOUND
        CALL PRSTR
        CALL PRNL
    ENDIF_BL 201

    STRMATCH_MEM STR_PATTERN_TEST, STR_PATTERN
    IF_ZERO 202
        LXI HL, MSG_STR_MATCH_OK
        CALL PRSTR
        CALL PRNL
    ENDIF_BL 202

    LXI HL, STR_TRIM_TEST
    LXI DE, STR_WORK_BUF
    LXI BC, 32
    CALL MEMCPY

    STRTRIM_MEM STR_WORK_BUF
    LXI HL, MSG_STR_TRIMMED
    CALL PRSTR
    LXI HL, STR_WORK_BUF
    CALL PRSTR
    MVI A, '"'
    CALL COUT
    CALL PRNL

    STRUPR_MEM STR_WORK_BUF
    LXI HL, MSG_STR_UPPER
    CALL PRSTR
    LXI HL, STR_WORK_BUF
    CALL PRSTR
    CALL PRNL
    RET

DO_MEMTEST:
    LXI     HL, MSG_MEM_HEADER
    CALL    PRSTR
    CALL    PRNL

    HEAP_INIT_MEM HEAP_BUF, 2048
    CALL PR_HEAP_INFO

    MVI BC, 100
    CALL MALLOC
    SHLD PTR1

    MVI BC, 200
    CALL MALLOC
    SHLD PTR2

    LHLD PTR2
    CALL FREE

    MVI BC, 80
    CALL MALLOC
    SHLD PTR3

    CALL PR_HEAP_INFO

    LHLD PTR1
    CALL FREE
    LHLD PTR3
    CALL FREE

    CALL MALLOC_COALESCE
    CALL PR_HEAP_INFO
    RET

DO_INT64TEST:
    LXI     HL, MSG_I64_HEADER
    CALL    PRSTR
    CALL    PRNL

    ADD64_MEM NUM64_A, NUM64_B, RES64_ADD
    LXI     HL, MSG_I64_SUM
    CALL    PRSTR
    PRDEC64_MEM RES64_ADD
    CALL    PRNL

    MUL64_MEM NUM64_C, NUM64_D, RES64_MUL
    LXI     HL, MSG_I64_PROD
    CALL    PRSTR
    PRDEC64_MEM RES64_MUL
    CALL    PRNL

    DIV64_MEM NUM64_E, NUM64_F, RES64_DIV, RES64_REM
    LXI     HL, MSG_I64_QUOT
    CALL    PRSTR
    PRDEC64_MEM RES64_DIV
    LXI     HL, MSG_I64_REM
    CALL    PRSTR
    PRDEC64_MEM RES64_REM
    CALL    PRNL
    RET

DO_INT32TEST:
    LXI     HL, MSG_I32_HEADER
    CALL    PRSTR
    CALL    PRNL

    ADD32_MEM NUM32_A, NUM32_B, RES32_ADD
    LXI     HL, MSG_I32_SUM
    CALL    PRSTR
    PRDEC32_MEM RES32_ADD
    CALL    PRNL

    MUL32_MEM NUM32_C, NUM32_D, RES32_MUL
    LXI     HL, MSG_I32_PROD
    CALL    PRSTR
    PRDEC32_MEM RES32_MUL
    CALL    PRNL

    DIV32_MEM NUM32_E, NUM32_F, RES32_DIV, RES32_REM
    LXI     HL, MSG_I32_QUOT
    CALL    PRSTR
    PRDEC32_MEM RES32_DIV
    CALL    PRNL
    RET

DO_CRCTEST:
    LXI     HL, MSG_CRC_HEADER
    CALL    PRSTR
    CALL    PRNL

    CRC16_BUF_MEM MSG_CRC_BENCHMARK, 9
    CALL    PR_CRC16
    CALL    PRNL
    RET

DO_FIXTEST:
    LXI     HL, MSG_FIX_HEADER
    CALL    PRSTR
    CALL    PRNL

    LXI     HL, FIX_VAL1_DATA
    CALL    FIX_LOAD
    FIX_ADD_MEM FIX_VAL2_DATA
    LXI     HL, MSG_FIX_SUM
    CALL    PRSTR
    CALL    PR_FIX
    CALL    PRNL
    RET

DO_BCDTEST:
    LXI     HL, MSG_BCD_HEADER
    CALL    PRSTR
    CALL    PRNL

    LXI     HL, BCD_NUM1
    LXI     DE, BCD_RES_ADD
    LXI     BC, 4
    CALL    MEMCPY

    BCD_ADD_MEM BCD_RES_ADD, BCD_NUM2, 4
    LXI     HL, MSG_BCD_SUM
    CALL    PRSTR
    BCD_PRINT_MEM BCD_RES_ADD, 4
    CALL    PRNL
    RET

DO_FPTEST:
    LXI     HL, MSG_FP_HEADER
    CALL    PRSTR
    CALL    PRNL

    LXI     H, 150
    CALL    INT_TO_FP
    LXI     HL, VAR_A
    CALL    FP_STORE

    LXI     H, 25
    CALL    INT_TO_FP
    LXI     HL, VAR_B
    CALL    FP_STORE

    LXI     HL, VAR_A
    CALL    FP_LOAD
    FP_ADD_MEM VAR_B
    LXI     HL, MSG_FP_SUM
    CALL    PRSTR
    CALL    PR_FLOAT
    CALL    PRNL
    RET


; -----------------------------------------------------------------------------
; PROMPT & READ LINE DEMONSTRATION ROUTINE (v14)
; -----------------------------------------------------------------------------
DO_ASK:
    LXI     HL, MSG_ASK_HEADER
    CALL    PRSTR
    CALL    PRNL

    ; Demonstrate PROMPT_GETLINE_MEM macro
    PROMPT_GETLINE_MEM MSG_ASK_PROMPT, ASK_BUF, 40
    ; HL now points to entered string, A = length

    PUSH    HL
    PUSH    PSW
    LXI     HL, MSG_ASK_REPLY
    CALL    PRSTR
    POP     PSW
    POP     HL
    CALL    PRSTR
    LXI     HL, MSG_ASK_BRACKET
    CALL    PRSTR
    CALL    PRNL
    RET

DO_DIR:
    LHLD    ARG2_PTR
    MOV     A, M
    ORA     A
    IF_ZERO 10
        LXI     HL, STR_ALL_FILES
    ENDIF_BL 10
    LXI     DE, TEMP_FCB
    CALL    PARSE_FCB
    LXI     DE, TEMP_FCB
    CALL    DIR_LIST
    RET

DO_TYPE:
    LHLD    ARG2_PTR
    MOV     A, M
    ORA     A
    IF_ZERO 11
        LXI     HL, MSG_NO_ARG
        CALL    PRSTR
        CALL    PRNL
        RET
    ENDIF_BL 11

    LXI     DE, TEMP_FCB
    CALL    PARSE_FCB
    LXI     DE, TEMP_FCB
    CALL    FOPEN
    CPI     0FFH
    IF_ZERO 12
        LXI     HL, MSG_NOT_FOUND
        CALL    PRSTR
        CALL    PRNL
        RET
    ENDIF_BL 12

    LXI     DE, TEMP_FCB
    CALL    FSEEK_START

TYPE_READ_LOOP:
    LXI     DE, DEFAULT_DMA
    CALL    FSET_DMA
    LXI     DE, TEMP_FCB
    CALL    FREAD
    ORA     A
    JNZ     TYPE_DONE

    LXI     HL, DEFAULT_DMA
    MVI     B, 128
TYPE_CHAR_LOOP:
    MOV     A, M
    CPI     EOF_MARK
    JZ      TYPE_DONE
    CALL    COUT
    INX     HL
    DCR     B
    JNZ     TYPE_CHAR_LOOP
    JMP     TYPE_READ_LOOP

TYPE_DONE:
    CALL    PRNL
    RET

DO_DEL:
    LHLD    ARG2_PTR
    MOV     A, M
    ORA     A
    IF_ZERO 13
        LXI     HL, MSG_NO_ARG
        CALL    PRSTR
        CALL    PRNL
        RET
    ENDIF_BL 13

    LXI     DE, TEMP_FCB
    CALL    PARSE_FCB
    LXI     DE, TEMP_FCB
    CALL    FDELETE
    CPI     0FFH
    IF_ZERO 14
        LXI     HL, MSG_NOT_FOUND
        CALL    PRSTR
        CALL    PRNL
        RET
    ELSE_BL 14
        LXI     HL, MSG_DELETED
        CALL    PRSTR
        CALL    PRNL
    ENDIF_ELSE 14
    RET

TOKENIZE:
    MOV     D, H
    MOV     E, L
TK_LOOP:
    MOV     A, M
    ORA     A
    JZ      TK_END
    CPI     ' '
    JZ      TK_SPLIT
    CALL    UPPERCASE
    MOV     M, A
    INX     HL
    JMP     TK_LOOP
TK_SPLIT:
    MVI     M, 0
    INX     HL
TK_SKIP_SP:
    MOV     A, M
    CPI     ' '
    JNZ     TK_END
    INX     HL
    JMP     TK_SKIP_SP
TK_END:
    XCHG
    RET

F_GETDRV_CALL:
    PUSH    B
    PUSH    D
    PUSH    H
    MVI     C, F_GETDRV
    CALL    BDOS
    POP     H
    POP     D
    POP     B
    RET


; -----------------------------------------------------------------------------
; CONSTANTS AND STRINGS
; -----------------------------------------------------------------------------
MSG_ASK_HEADER: DB  '--- Prompt & Read Line Utility Test ---', 0
MSG_ASK_PROMPT: DB  'Please enter a response prompt> ', 0
MSG_ASK_REPLY:  DB  'You responded with: [', 0
MSG_ASK_BRACKET: DB  ']', 0
MSG_BANNER:     DB  '==================================================', CR, LF
                DB  '  Gemini CP/M 2.2 Shell & ANSI Terminal (v14.0)   ', CR, LF
                DB  '  Commands: ARGS, VT100, DIR, TYPE, DEL, INFO, IO,', CR, LF
                DB  '            FPTEST, BCDTEST, FIXTEST, CRCTEST,', CR, LF
                DB  '            INT32TEST, INT64TEST, MEMTEST, STRTEST, EXIT', CR, LF
                DB  '==================================================', 0
MSG_PROMPT:     DB  '> ', 0
MSG_UNKNOWN:    DB  'Error: Unknown command. Type ARGS, VT100, DIR, INFO, or EXIT.', 0
MSG_NO_ARG:     DB  'Error: Missing required argument.', 0
MSG_NOT_FOUND:  DB  'Error: File not found.', 0
MSG_DELETED:    DB  'File successfully deleted.', 0
MSG_EXIT:       DB  'Exiting shell. Warm booting CP/M...', 0

MSG_VT_TITLE:   DB  '*** VT100 / ANSI TERMINAL CONTROL ***', 0
MSG_VT_STATUS:  DB  ' STATUS: REVERSE VIDEO TEXT IN ANSI BOX ', 0
MSG_VT_DONE:    DB  'VT100 ANSI demonstration completed successfully.', 0

MSG_STR_HEADER:   DB  '--- Extended String Manipulation Package Test ---', 0
MSG_STR_HAYSTACK: DB  'Target Haystack: "CP/M 2.2 Assembly Language Subroutines Package"', 0
STR_NEEDLE1:      DB  'Assembly', 0
MSG_STR_FOUND:    DB  'Substring Search: "Assembly" FOUND in haystack!', 0
STR_PATTERN_TEST: DB  'CPM22LIB.ASM', 0
STR_PATTERN:      DB  'CPM??LIB.*', 0
MSG_STR_MATCH_OK: DB  'Wildcard Match: "CPM22LIB.ASM" MATCHES "CPM??LIB.*"!', 0
STR_TRIM_TEST:    DB  '   CP/M 2.2 System   ', 0
MSG_STR_TRIMMED:  DB  'Trimmed Result: "', 0
MSG_STR_UPPER:    DB  'Uppercase Result: ', 0

MSG_MEM_HEADER:   DB  '--- Dynamic Heap Memory Allocation Test ---', 0
MSG_I64_HEADER:   DB  '--- 64-Bit Binary Integer Arithmetic Test ---', 0
MSG_I64_SUM:      DB  '64-Bit Sum (10^19 + 5*10^18): ', 0
MSG_I64_PROD:     DB  '64-Bit Product (123456789 * 987654321): ', 0
MSG_I64_QUOT:     DB  '64-Bit Quotient (9876543210987654321 / 123456789): ', 0
MSG_I64_REM:      DB  '64-Bit Remainder: ', 0

MSG_I32_HEADER:   DB  '--- 32-Bit Binary Integer Arithmetic Test ---', 0
MSG_I32_SUM:      DB  '32-Bit Sum (3,000,000,000 + 123,456,789): ', 0
MSG_I32_PROD:     DB  '32-Bit Product (12,345 * 67,890): ', 0
MSG_I32_QUOT:     DB  '32-Bit Quotient (1,000,000 / 3): ', 0

MSG_CRC_HEADER:   DB  '--- CRC-16-CCITT Data Integrity Test ---', 0
MSG_CRC_BENCHMARK: DB '123456789', 0

MSG_FIX_HEADER:   DB  '--- 16.16 Fixed-Point Binary Arithmetic Test ---', 0
MSG_FIX_SUM:      DB  'Fixed-Point Sum (12.500 + 3.250): ', 0

MSG_BCD_HEADER:   DB  '--- Packed BCD Math Test ---', 0
MSG_BCD_SUM:      DB  '8-Digit BCD Sum (87654321 + 12345678): ', 0

MSG_FP_HEADER:    DB  '--- 32-Bit Software Floating-Point Test ---', 0
MSG_FP_SUM:       DB  'Floating-Point Sum (150.0 + 25.0): ', 0

CMD_DIR:        DB  'DIR', 0
CMD_TYPE:       DB  'TYPE', 0
CMD_DEL:        DB  'DEL', 0
CMD_INFO:       DB  'INFO', 0
CMD_IO:         DB  'IO', 0
CMD_ARGS:       DB  'ARGS', 0
CMD_VT100:      DB  'VT100', 0
CMD_FPTEST:     DB  'FPTEST', 0
CMD_BCDTEST:    DB  'BCDTEST', 0
CMD_FIXTEST:    DB  'FIXTEST', 0
CMD_CRCTEST:    DB  'CRCTEST', 0
CMD_INT32TEST:  DB  'INT32TEST', 0
CMD_INT64TEST:  DB  'INT64TEST', 0
CMD_MEMTEST:    DB  'MEMTEST', 0
CMD_STRTEST:    DB  'STRTEST', 0
CMD_ASK:        DB  'ASK', 0
CMD_EXIT:       DB  'EXIT', 0
STR_ALL_FILES:  DB  '*.*', 0

; -----------------------------------------------------------------------------
; DATA BUFFERS
; -----------------------------------------------------------------------------
ARG1_PTR:       DW  0
ARG2_PTR:       DW  0
PTR1:           DW  0
PTR2:           DW  0
PTR3:           DW  0

NUM64_A:        DB  00H, 00H, 70H, 8BH, 0B1H, 19H, 8AH, 8AH ; 10^19
NUM64_B:        DB  00H, 00H, 78H, 0C5H, 58H, 0CDH, 45H, 45H ; 5*10^18
RES64_ADD:      DS  8

NUM64_C:        DB  15H, 0CDH, 5BH, 07H, 00H, 00H, 00H, 00H ; 123456789
NUM64_D:        DB  B1H, 68H, DEH, 3AH, 00H, 00H, 00H, 00H ; 987654321
RES64_MUL:      DS  8

NUM64_E:        DB  B1H, 68H, DEH, 3AH, 70H, 8BH, 0B1H, 89H ; 9876543210987654321
NUM64_F:        DB  15H, 0CDH, 5BH, 07H, 00H, 00H, 00H, 00H ; 123456789
RES64_DIV:      DS  8
RES64_REM:      DS  8

NUM32_A:        DB  00H, 28H, 6BH, 0B2H ; 3,000,000,000
NUM32_B:        DB  15H, 0CDH, 5BH, 07H ; 123,456,789
RES32_ADD:      DS  4

NUM32_C:        DB  39H, 30H, 00H, 00H ; 12,345
NUM32_D:        DB  12H, 009H, 01H, 00H ; 67,890
RES32_MUL:      DS  4

NUM32_E:        DB  40H, 42H, 0FH, 00H ; 1,000,000
NUM32_F:        DB  03H, 00H, 00H, 00H ; 3
RES32_DIV:      DS  4

FIX_VAL1_DATA:  DB  00H, 80H, 0CH, 00H ; 12.500
FIX_VAL2_DATA:  DB  00H, 40H, 03H, 00H ; 3.250

BCD_NUM1:       DB  21H, 43H, 65H, 87H ; 87654321
BCD_NUM2:       DB  78H, 56H, 34H, 12H ; 12345678
BCD_RES_ADD:    DS  4

VAR_A:          DS  4
VAR_B:          DS  4

HEAP_BUF:       DS  2048
STR_WORK_BUF:   DS  32
ASK_BUF:        DS  45          ; Buffer for prompt response
TEMP_FCB:       DS  36
CMD_BUF:        DS  64

    INCLUDE CPM22LIB-v14.ASM

                DS  32
STACK:          EQU $

    END START
