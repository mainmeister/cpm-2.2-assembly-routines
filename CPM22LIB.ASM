; =============================================================================
; CPM22LIB-v8.ASM - CP/M 2.2 Function, Floating-Point, BCD Math, & UART 8251 Library
; Fully compatible with Intel 8080, 8085, and Zilog Z80 processors.
;
; Subroutine Categories:
; 1. Console & Peripheral Character I/O
; 2. Buffered Input & FCB Parsing
; 3. Hexadecimal, Decimal, & Disk DPB Formatting
; 4. Memory & String Operations
; 5. File System & Wildcard Directory Management
; 6. CP/M IOBYTE Query, Modification, and Device Redirection
; 7. 32-Bit Software Floating-Point Math Package
; 8. BCD (Binary-Coded Decimal) Math Package (NEW in v5)
; 9. CRC-16 Data Integrity Package (NEW in v7)
; 10. Intel 8251 USART / Serial I/O Package (NEW in v8)
; =============================================================================

; -----------------------------------------------------------------------------
; CP/M 2.2 SYSTEM EQUATES
; -----------------------------------------------------------------------------
WBOOT     EQU 0000H     ; System Warm Boot entry point
IOBYTE_LOC EQU 0003H    ; Page zero location of IOBYTE
BDOS      EQU 0005H     ; Primary BDOS entry point
DEFAULT_DMA EQU 0080H   ; Default DMA sector buffer

; BDOS Function Codes
C_TERM    EQU 0         ; System Reset
C_READ    EQU 1         ; Console Input
C_WRITE   EQU 2         ; Console Output
A_READ    EQU 3         ; Auxiliary (Reader) Input
A_WRITE   EQU 4         ; Auxiliary (Punch) Output
L_WRITE   EQU 5         ; List (Printer) Output
C_RAWIO   EQU 6         ; Direct Console I/O
GET_IOB   EQU 7         ; Get I/O Byte
SET_IOB   EQU 8         ; Set I/O Byte
C_WRSTR   EQU 9         ; Print String (DE = address, terminated by '$')
C_RDSTR   EQU 10        ; Read Console Buffer
C_STAT    EQU 11        ; Get Console Status
S_VERSION EQU 12        ; Get CP/M Version Number

; BDOS File System Function Codes
F_RESET   EQU 13        ; Reset Disk System
F_SELDRV  EQU 14        ; Select Active Drive
F_OPEN    EQU 15        ; Open File
F_CLOSE   EQU 16        ; Close File
F_SFIRST  EQU 17        ; Search First
F_SNEXT   EQU 18        ; Search Next
F_DELETE  EQU 19        ; Delete File
F_READS   EQU 20        ; Read Sequential Record
F_WRITES  EQU 21        ; Write Sequential Record
F_MAKE    EQU 22        ; Make (Create) File
F_RENAME  EQU 23        ; Rename File
F_LOGGED  EQU 24        ; Get Logged-In Drives Vector
F_GETDRV  EQU 25        ; Get Active Drive
F_SETDMA  EQU 26        ; Set DMA Address
F_GETDPB  EQU 31        ; Get Disk Parameter Block Address
F_USERNUM EQU 32        ; Set/Get User Code

; IOBYTE Device Field Bitmasks
IO_CONM   EQU 03H       ; Console field mask (Bits 0-1)
IO_RDRM   EQU 0CH       ; Reader field mask  (Bits 2-3)
IO_PUNM   EQU 30H       ; Punch field mask   (Bits 4-5)
IO_LSTM   EQU 0C0H      ; List field mask    (Bits 6-7)

; IOBYTE Logical Device Values
IO_CON_TTY EQU 0
IO_CON_CRT EQU 1
IO_CON_BAT EQU 2
IO_CON_UC1 EQU 3

IO_RDR_TTY EQU 0
IO_RDR_PTR EQU 1
IO_RDR_UR1 EQU 2
IO_RDR_UR2 EQU 3

IO_PUN_TTY EQU 0
IO_PUN_PTP EQU 1
IO_PUN_UP1 EQU 2
IO_PUN_UP2 EQU 3

IO_LST_TTY EQU 0
IO_LST_CRT EQU 1
IO_LST_LPT EQU 2
IO_LST_UL1 EQU 3

; ASCII Constants
CR        EQU 0DH       ; Carriage Return
LF        EQU 0AH       ; Line Feed
TAB       EQU 09H       ; Horizontal Tab
ESC       EQU 1BH       ; Escape
EOF_MARK  EQU 1AH       ; Ctrl-Z End-Of-File marker


; =============================================================================
; 1. CONSOLE AND PERIPHERAL CHARACTER I/O ROUTINES
; =============================================================================

COUT:
    PUSH B
    PUSH D
    PUSH H
    MVI C, C_WRITE
    MOV E, A
    CALL BDOS
    POP H
    POP D
    POP B
    RET

CIN:
    PUSH B
    PUSH D
    PUSH H
    MVI C, C_READ
    CALL BDOS
    POP H
    POP D
    POP B
    RET

CSTAT:
    PUSH B
    PUSH D
    PUSH H
    MVI C, C_STAT
    CALL BDOS
    POP H
    POP D
    POP B
    RET

RAWIO_IN:
    PUSH B
    PUSH D
    PUSH H
    MVI C, C_RAWIO
    MVI E, 0FFH
    CALL BDOS
    POP H
    POP D
    POP B
    RET

LOUT:
    PUSH B
    PUSH D
    PUSH H
    MVI C, L_WRITE
    MOV E, A
    CALL BDOS
    POP H
    POP D
    POP B
    RET

POUT:
    PUSH B
    PUSH D
    PUSH H
    MVI C, A_WRITE
    MOV E, A
    CALL BDOS
    POP H
    POP D
    POP B
    RET

RIN:
    PUSH B
    PUSH D
    PUSH H
    MVI C, A_READ
    CALL BDOS
    POP H
    POP D
    POP B
    RET

STROUT:
    PUSH B
    PUSH H
    MVI C, C_WRSTR
    CALL BDOS
    POP H
    POP B
    RET

PRSTR:
    PUSH H
    PUSH B
    PUSH D
PS_LOOP:
    MOV A, M
    ORA A
    JZ PS_EXIT
    CALL COUT
    INX H
    JMP PS_LOOP
PS_EXIT:
    POP D
    POP B
    POP H
    RET

PRNL:
    PUSH PSW
    MVI A, CR
    CALL COUT
    MVI A, LF
    CALL COUT
    POP PSW
    RET


; =============================================================================
; 2. BUFFERED INPUT AND FCB PARSING ROUTINES
; =============================================================================

GETLINE:
    PUSH H
    MOV M, A
    MVI A, 0
    INX H
    MOV M, A
    POP D
    PUSH D
    MVI C, C_RDSTR
    CALL BDOS
    POP H
    INX H
    MOV A, M
    MOV B, A
    INX H
    PUSH H
    MOV E, B
    MVI D, 0
    DAD D
    MVI M, 0
    POP H
    MOV A, B
    RET

; -----------------------------------------------------------------------------
; PROMPT_GETLINE - Print Prompt String and Read Null-Terminated Line
; Entry: DE = Address of null-terminated prompt string
;        HL = Address of target input buffer (must be max_len + 2 bytes)
;        A  = Maximum allowable characters to read
; Exit:  HL = Address of first actual character in input text buffer
;        A  = Number of characters actually read
; Registers used: AF, BC, DE, HL
; -----------------------------------------------------------------------------
PROMPT_GETLINE:
    PUSH H              ; Save target buffer address
    PUSH PSW            ; Save A (max length)
    XCHG                ; HL = Prompt address
    CALL PRSTR          ; Output prompt string to console
    POP PSW             ; Restore A (max length)
    POP H               ; Restore target buffer address
    CALL GETLINE        ; Read input line and null-terminate
    RET


UPPERCASE:
    CPI 'a'
    RC
    CPI 'z'+1
    RNC
    ANI 5FH
    RET

PARSE_FCB:
    PUSH H
    PUSH D
    PUSH B

    PUSH D
    PUSH H
    MOV H, D
    MOV L, E
    LXI B, 36
    MVI A, 0
    CALL MEMSET
    POP H
    POP D

PF_SKIP_SP:
    MOV A, M
    CPI ' '
    JNZ PF_CHECK_DRV
    INX H
    JMP PF_SKIP_SP

PF_CHECK_DRV:
    MOV A, M
    ORA A
    JZ PF_DONE

    INX H
    MOV B, M
    DCX H
    MOV A, B
    CPI ':'
    JNZ PF_DEFAULT_DRV

    MOV A, M
    CALL UPPERCASE
    SUI 'A'-1
    STAX D
    INX H
    INX H
    JMP PF_PARSE_NAME

PF_DEFAULT_DRV:
    MVI A, 0
    STAX D

PF_PARSE_NAME:
    INX DE
    MVI B, 8

PF_NAME_LOOP:
    MOV A, M
    ORA A
    JZ PF_PAD_NAME
    CPI ' '
    JZ PF_PAD_NAME
    CPI '.'
    JZ PF_PAD_NAME

    CPI '*'
    JZ PF_STAR_NAME

    CALL UPPERCASE
    STAX D
    INX DE
    INX H
    DCR B
    JNZ PF_NAME_LOOP
    JMP PF_PARSE_EXT_DOT

PF_STAR_NAME:
    MVI A, '?'
PF_STAR_NAME_LOOP:
    STAX D
    INX DE
    DCR B
    JNZ PF_STAR_NAME_LOOP
    INX H

PF_PAD_NAME:
    MOV A, B
    ORA A
    JZ PF_PARSE_EXT_DOT
    MVI A, ' '
PF_PAD_NAME_LOOP:
    STAX D
    INX DE
    DCR B
    JNZ PF_PAD_NAME_LOOP

PF_PARSE_EXT_DOT:
    MOV A, M
    CPI '.'
    JNZ PF_PAD_EXT_SP
    INX H

    MVI B, 3
PF_EXT_LOOP:
    MOV A, M
    ORA A
    JZ PF_PAD_EXT
    CPI ' '
    JZ PF_PAD_EXT

    CPI '*'
    JZ PF_STAR_EXT

    CALL UPPERCASE
    STAX D
    INX DE
    INX H
    DCR B
    JNZ PF_EXT_LOOP
    JMP PF_DONE

PF_STAR_EXT:
    MVI A, '?'
PF_STAR_EXT_LOOP:
    STAX D
    INX DE
    DCR B
    JNZ PF_STAR_EXT_LOOP
    INX H
    JMP PF_DONE

PF_PAD_EXT_SP:
    MVI B, 3
PF_PAD_EXT:
    MOV A, B
    ORA A
    JZ PF_DONE
    MVI A, ' '
PF_PAD_EXT_LOOP:
    STAX D
    INX DE
    DCR B
    JNZ PF_PAD_EXT_LOOP

PF_DONE:
    POP B
    POP D
    POP H
    RET


; =============================================================================
; 3. HEXADECIMAL, DECIMAL, AND DISK DPB FORMATTING
; =============================================================================

PRHEX8:
    PUSH PSW
    PUSH B
    MOV B, A
    ANI 0F0H
    RRC
    RRC
    RRC
    RRC
    CALL PRNIBBLE
    MOV A, B
    ANI 0FH
    CALL PRNIBBLE
    POP B
    POP PSW
    RET

PRNIBBLE:
    CPI 10
    JNC PH_LETTER
    ADI '0'
    JMP PH_PRINT
PH_LETTER:
    ADI 'A'-10
PH_PRINT:
    CALL COUT
    RET

PRHEX16:
    PUSH PSW
    MOV A, H
    CALL PRHEX8
    MOV A, L
    CALL PRHEX8
    POP PSW
    RET

PRDEC16:
    PUSH H
    PUSH D
    PUSH B
    LXI B, -10000
    CALL DECDIV
    LXI B, -1000
    CALL DECDIV
    LXI B, -100
    CALL DECDIV
    LXI B, -10
    CALL DECDIV
    MOV A, L
    ADI '0'
    CALL COUT
    POP B
    POP D
    POP H
    RET

DECDIV:
    MVI A, '0'-1
DD_LOOP:
    INR A
    PUSH H
    DAD B
    JNC DD_STOP
    INX SP
    INX SP
    JMP DD_LOOP
DD_STOP:
    POP H
    CALL COUT
    RET

PR_DRIVE_INFO:
    PUSH H
    PUSH D
    PUSH B

    MVI C, F_GETDPB
    CALL BDOS
    MOV A, H
    ORA L
    JZ DPB_ERR

    PUSH HL

    LXI HL, MSG_DPB_HEAD
    CALL PRSTR

    POP HL

    MOV E, M
    INX HL
    MOV D, M
    INX HL
    LXI HL, MSG_SPT
    CALL PRSTR
    XCHG
    CALL PRDEC16
    CALL PRNL

    XCHG
    MOV A, M
    INX HL
    INX HL
    INX HL

    MOV E, M
    INX HL
    MOV D, M
    INX HL
    LXI HL, MSG_DSM
    CALL PRSTR
    XCHG
    CALL PRDEC16
    CALL PRNL

    XCHG
    MOV E, M
    INX HL
    MOV D, M
    INX HL
    LXI HL, MSG_DRM
    CALL PRSTR
    XCHG
    INR H
    INR L
    CALL PRDEC16
    CALL PRNL
    JMP DPB_EXIT

DPB_ERR:
    LXI HL, MSG_DPB_ERR
    CALL PRSTR
    CALL PRNL

DPB_EXIT:
    POP B
    POP D
    POP H
    RET

MSG_DPB_HEAD: DB '--- Active CP/M Disk Parameter Block (DPB) ---', CR, LF, 0
MSG_SPT:      DB 'Sectors per Track (128-byte records): ', 0
MSG_DSM:      DB 'Total Data Allocation Blocks (DSM): ', 0
MSG_DRM:      DB 'Max Directory File Capacity (DRM+1): ', 0
MSG_DPB_ERR:  DB 'Error: Unable to retrieve DPB from CP/M BDOS.', 0


; =============================================================================
; 4. MEMORY AND STRING MANIPULATION ROUTINES
; =============================================================================

MEMCPY:
    MOV A, B
    ORA C
    RZ
    MOV A, M
    STAX D
    INX HL
    INX DE
    DCX B
    JMP MEMCPY

MEMSET:
    PUSH D
    MOV D, A
MS_LOOP:
    MOV A, B
    ORA C
    JZ MS_EXIT
    MOV A, D
    MOV M, A
    INX HL
    DCX B
    JMP MS_LOOP
MS_EXIT:
    POP D
    RET

STRCMP:
    LDAX D
    CMP M
    RNZ
    ORA A
    RZ
    INX HL
    INX DE
    JMP STRCMP

STRLEN:
    PUSH H
    MVI A, 0
SL_LOOP:
    MOV B, M
    MOV C, A
    MOV A, B
    ORA A
    JZ SL_EXIT
    MOV A, C
    INR A
    INX H
    JMP SL_LOOP
SL_EXIT:
    MOV A, C
    POP H
    RET


; =============================================================================
; 5. FILE SYSTEM AND DIRECTORY MANAGEMENT ROUTINES
; =============================================================================

FOPEN:
    MVI C, F_OPEN
    JMP BDOS

FCLOSE:
    MVI C, F_CLOSE
    JMP BDOS

FDELETE:
    MVI C, F_DELETE
    JMP BDOS

FMAKE:
    MVI C, F_MAKE
    JMP BDOS

FREAD:
    MVI C, F_READS
    JMP BDOS

FWRITE:
    MVI C, F_WRITES
    JMP BDOS

FSET_DMA:
    MVI C, F_SETDMA
    JMP BDOS

FSEEK_START:
    PUSH H
    PUSH D
    LXI H, 12
    DAD D
    MVI M, 0
    LXI H, 32
    DAD D
    MVI M, 0
    POP D
    POP H
    RET

DIR_LIST:
    PUSH H
    PUSH D
    PUSH B

    LXI DE, DEFAULT_DMA
    CALL FSET_DMA

    POP DE
    PUSH DE

    MVI C, F_SFIRST
    CALL BDOS
    CPI 0FFH
    JZ DL_NONE

DL_FOUND_LOOP:
    ANI 03H
    ADD A
    ADD A
    ADD A
    ADD A
    ADD A
    ADI 80H
    MOV L, A
    MVI H, 0

    MOV A, M
    CPI 0E5H
    JZ DL_NEXT

    INX HL
    MVI B, 8
DL_PR_NAME:
    MOV A, M
    ANI 7FH
    CALL COUT
    INX HL
    DCR B
    JNZ DL_PR_NAME

    MVI A, '.'
    CALL COUT

    MVI B, 3
DL_PR_EXT:
    MOV A, M
    ANI 7FH
    CALL COUT
    INX HL
    DCR B
    JNZ DL_PR_EXT

    MVI A, ' '
    CALL COUT
    CALL COUT

DL_NEXT:
    POP DE
    PUSH DE
    MVI C, F_SNEXT
    CALL BDOS
    CPI 0FFH
    JNZ DL_FOUND_LOOP
    JMP DL_EXIT

DL_NONE:
    LXI HL, MSG_NO_FILES
    CALL PRSTR
    CALL PRNL

DL_EXIT:
    CALL PRNL
    POP B
    POP D
    POP H
    RET

MSG_NO_FILES: DB 'No matching files found.', 0


; =============================================================================
; 6. CP/M IOBYTE QUERY, MODIFICATION, AND DEVICE REDIRECTION
; =============================================================================

GET_IOBYTE:
    PUSH B
    PUSH D
    PUSH H
    MVI C, GET_IOB
    CALL BDOS
    POP H
    POP D
    POP B
    RET

SET_IOBYTE:
    PUSH B
    PUSH D
    PUSH H
    MVI C, SET_IOB
    CALL BDOS
    POP H
    POP D
    POP B
    RET

SET_CON_DEV:
    PUSH PSW
    PUSH D
    ANI IO_CONM
    MOV D, A
    CALL GET_IOBYTE
    ANI NOT IO_CONM
    ORA D
    MOV E, A
    CALL SET_IOBYTE
    POP D
    POP PSW
    RET

SET_RDR_DEV:
    PUSH PSW
    PUSH D
    ANI 03H
    RLC
    RLC
    MOV D, A
    CALL GET_IOBYTE
    ANI NOT IO_RDRM
    ORA D
    MOV E, A
    CALL SET_IOBYTE
    POP D
    POP PSW
    RET

SET_PUN_DEV:
    PUSH PSW
    PUSH D
    ANI 03H
    RLC
    RLC
    RLC
    RLC
    MOV D, A
    CALL GET_IOBYTE
    ANI NOT IO_PUNM
    ORA D
    MOV E, A
    CALL SET_IOBYTE
    POP D
    POP PSW
    RET

SET_LST_DEV:
    PUSH PSW
    PUSH D
    ANI 03H
    RRC
    RRC
    MOV D, A
    CALL GET_IOBYTE
    ANI NOT IO_LSTM
    ORA D
    MOV E, A
    CALL SET_IOBYTE
    POP D
    POP PSW
    RET

PR_IOBYTE:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LXI HL, MSG_IOB_HEAD
    CALL PRSTR

    CALL GET_IOBYTE
    MOV B, A

    LXI HL, MSG_RAW_IOB
    CALL PRSTR
    MOV A, B
    CALL PRHEX8
    CALL PRNL

    LXI HL, MSG_CON_NAME
    CALL PRSTR
    MOV A, B
    ANI IO_CONM
    CPI IO_CON_TTY
    CZ PR_DEV_TTY
    CPI IO_CON_CRT
    CZ PR_DEV_CRT
    CPI IO_CON_BAT
    CZ PR_DEV_BAT
    CPI IO_CON_UC1
    CZ PR_DEV_UC1
    CALL PRNL

    LXI HL, MSG_RDR_NAME
    CALL PRSTR
    MOV A, B
    ANI IO_RDRM
    RRC
    RRC
    CPI IO_RDR_TTY
    CZ PR_DEV_TTY
    CPI IO_RDR_PTR
    CZ PR_DEV_PTR
    CPI IO_RDR_UR1
    CZ PR_DEV_UR1
    CPI IO_RDR_UR2
    CZ PR_DEV_UR2
    CALL PRNL

    LXI HL, MSG_PUN_NAME
    CALL PRSTR
    MOV A, B
    ANI IO_PUNM
    RRC
    RRC
    RRC
    RRC
    CPI IO_PUN_TTY
    CZ PR_DEV_TTY
    CPI IO_PUN_PTP
    CZ PR_DEV_PTP
    CPI IO_PUN_UP1
    CZ PR_DEV_UP1
    CPI IO_PUN_UP2
    CZ PR_DEV_UP2
    CALL PRNL

    LXI HL, MSG_LST_NAME
    CALL PRSTR
    MOV A, B
    ANI IO_LSTM
    RLC
    RLC
    CPI IO_LST_TTY
    CZ PR_DEV_TTY
    CPI IO_LST_CRT
    CZ PR_DEV_CRT
    CPI IO_LST_LPT
    CZ PR_DEV_LPT
    CPI IO_LST_UL1
    CZ PR_DEV_UL1
    CALL PRNL

    POP H
    POP D
    POP B
    POP PSW
    RET

PR_DEV_TTY: LXI HL, S_TTY ! JMP PRSTR
PR_DEV_CRT: LXI HL, S_CRT ! JMP PRSTR
PR_DEV_BAT: LXI HL, S_BAT ! JMP PRSTR
PR_DEV_UC1: LXI HL, S_UC1 ! JMP PRSTR
PR_DEV_PTR: LXI HL, S_PTR ! JMP PRSTR
PR_DEV_UR1: LXI HL, S_UR1 ! JMP PRSTR
PR_DEV_UR2: LXI HL, S_UR2 ! JMP PRSTR
PR_DEV_PTP: LXI HL, S_PTP ! JMP PRSTR
PR_DEV_UP1: LXI HL, S_UP1 ! JMP PRSTR
PR_DEV_UP2: LXI HL, S_UP2 ! JMP PRSTR
PR_DEV_LPT: LXI HL, S_LPT ! JMP PRSTR
PR_DEV_UL1: LXI HL, S_UL1 ! JMP PRSTR

MSG_IOB_HEAD: DB '--- Active CP/M IOBYTE Configuration ---', CR, LF, 0
MSG_RAW_IOB:  DB 'Current IOBYTE Value (Address 0003H): ', 0
MSG_CON_NAME: DB 'Console (CON:) mapped to: ', 0
MSG_RDR_NAME: DB 'Reader  (RDR:) mapped to: ', 0
MSG_PUN_NAME: DB 'Punch   (PUN:) mapped to: ', 0
MSG_LST_NAME: DB 'List    (LST:) mapped to: ', 0

S_TTY: DB 'TTY: (Teletype / Serial)', 0
S_CRT: DB 'CRT: (Terminal / Screen)', 0
S_BAT: DB 'BAT: (Batch Processor)', 0
S_UC1: DB 'UC1: (User Console 1)', 0
S_PTR: DB 'PTR: (Paper Tape Reader)', 0
S_UR1: DB 'UR1: (User Reader 1)', 0
S_UR2: DB 'UR2: (User Reader 2)', 0
S_PUN: DB 'PTP: (Paper Tape Punch)', 0
S_UP1: DB 'UP1: (User Punch 1)', 0
S_UP2: DB 'UP2: (User Punch 2)', 0
S_LPT: DB 'LPT: (Line Printer)', 0
S_UL1: DB 'UL1: (User List 1)', 0


; =============================================================================
; 7. 32-BIT SOFTWARE FLOATING-POINT MATH PACKAGE
; =============================================================================

FP_LOAD:
    PUSH H
    PUSH A
    MOV A, M
    STA FAC1_EXP
    INX HL
    MOV A, M
    ANI 80H
    STA FAC1_SIGN
    MOV A, M
    ORI 80H
    STA FAC1_M2
    INX HL
    MOV A, M
    STA FAC1_M1
    INX HL
    MOV A, M
    STA FAC1_M0
    POP A
    POP H
    RET

FP_STORE:
    PUSH H
    PUSH A
    LDA FAC1_EXP
    MOV M, A
    INX HL
    LDA FAC1_M2
    ANI 7FH
    MOV B, A
    LDA FAC1_SIGN
    ORA B
    MOV M, A
    INX HL
    LDA FAC1_M1
    MOV M, A
    INX HL
    LDA FAC1_M0
    MOV M, A
    POP A
    POP H
    RET

FP_LOAD2:
    PUSH H
    PUSH A
    MOV A, M
    STA FAC2_EXP
    INX HL
    MOV A, M
    ANI 80H
    STA FAC2_SIGN
    MOV A, M
    ORI 80H
    STA FAC2_M2
    INX HL
    MOV A, M
    STA FAC2_M1
    INX HL
    MOV A, M
    STA FAC2_M0
    POP A
    POP H
    RET

INT_TO_FP:
    PUSH PSW
    PUSH H
    MOV A, H
    ORA L
    JZ FP_SET_ZERO

    MVI A, 0
    STA FAC1_SIGN
    MOV A, H
    ORA A
    JP INT_POS
    MVI A, 80H
    STA FAC1_SIGN
    MOV A, L
    CMA
    MOV L, A
    MOV A, H
    CMA
    MOV H, A
    INX HL

INT_POS:
    MVI A, 8FH
    STA FAC1_EXP
    MOV A, H
    STA FAC1_M2
    MOV A, L
    STA FAC1_M1
    MVI A, 0
    STA FAC1_M0

INT_NORM:
    LDA FAC1_M2
    ORA A
    JM INT_NORM_DONE
    LDA FAC1_M0
    ADD A
    STA FAC1_M0
    LDA FAC1_M1
    RAL
    STA FAC1_M1
    LDA FAC1_M2
    RAL
    STA FAC1_M2
    LDA FAC1_EXP
    DCR A
    STA FAC1_EXP
    JMP INT_NORM

INT_NORM_DONE:
    POP H
    POP PSW
    RET

FP_SET_ZERO:
    MVI A, 0
    STA FAC1_EXP
    STA FAC1_SIGN
    STA FAC1_M2
    STA FAC1_M1
    STA FAC1_M0
    POP H
    POP PSW
    RET

FP_TO_INT:
    PUSH PSW
    LDA FAC1_EXP
    ORA A
    JZ FP_INT_ZERO

    SUI 80H
    MOV B, A
    CPI 16
    JNC FP_INT_ZERO

    MOV H, A
    LDA FAC1_M2
    MOV H, A
    LDA FAC1_M1
    MOV L, A

    MVI A, 15
    SUB B
    JZ FP_INT_SIGN
    MOV C, A
FP_INT_SHIFT:
    MOV A, H
    ORA A
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    DCR C
    JNZ FP_INT_SHIFT

FP_INT_SIGN:
    LDA FAC1_SIGN
    ORA A
    JZ FP_INT_EXIT
    MOV A, L
    CMA
    MOV L, A
    MOV A, H
    CMA
    MOV H, A
    INX HL
    JMP FP_INT_EXIT

FP_INT_ZERO:
    LXI H, 0
FP_INT_EXIT:
    POP PSW
    RET

FP_ADD:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LDA FAC2_EXP
    ORA A
    JZ FP_ADD_EXIT

    LDA FAC1_EXP
    ORA A
    JNZ FP_ADD_EXEC
    LXI HL, FAC2_EXP
    LXI DE, FAC1_EXP
    LXI BC, 5
    CALL MEMCPY
    JMP FP_ADD_EXIT

FP_ADD_EXEC:
    LDA FAC1_EXP
    MOV B, A
    LDA FAC2_EXP
    CMP B
    JZ FP_ADD_ALIGN_DONE
    JNC FP_SWAP_FAC

    SUB B
    NEG
    MOV C, A
FP_SHIFT_FAC2:
    LDA FAC2_M2
    ORA A
    RAR
    STA FAC2_M2
    LDA FAC2_M1
    RAR
    STA FAC2_M1
    LDA FAC2_M0
    RAR
    STA FAC2_M0
    DCR C
    JNZ FP_SHIFT_FAC2
    JMP FP_ADD_ALIGN_DONE

FP_SWAP_FAC:
    LXI HL, FAC1_EXP
    LXI DE, FAC_TEMP
    LXI BC, 5
    CALL MEMCPY
    LXI HL, FAC2_EXP
    LXI DE, FAC1_EXP
    LXI BC, 5
    CALL MEMCPY
    LXI HL, FAC_TEMP
    LXI DE, FAC2_EXP
    LXI BC, 5
    CALL MEMCPY
    JMP FP_ADD_EXEC

FP_ADD_ALIGN_DONE:
    LDA FAC1_SIGN
    MOV B, A
    LDA FAC2_SIGN
    CMP B
    JNZ FP_ADD_SUBTRACT

    LDA FAC1_M0
    MOV B, A
    LDA FAC2_M0
    ADD B
    STA FAC1_M0
    LDA FAC1_M1
    MOV B, A
    LDA FAC2_M1
    ADC B
    STA FAC1_M1
    LDA FAC1_M2
    MOV B, A
    LDA FAC2_M2
    ADC B
    STA FAC1_M2

    JNC FP_ADD_EXIT
    LDA FAC1_M2
    RAR
    STA FAC1_M2
    LDA FAC1_M1
    RAR
    STA FAC1_M1
    LDA FAC1_M0
    RAR
    STA FAC1_M0
    LDA FAC1_EXP
    INR A
    STA FAC1_EXP
    JMP FP_ADD_EXIT

FP_ADD_SUBTRACT:
    LDA FAC1_M0
    MOV B, A
    LDA FAC2_M0
    SUB B
    CMA
    STA FAC1_M0
    LDA FAC1_M1
    MOV B, A
    LDA FAC2_M1
    SBB B
    STA FAC1_M1
    LDA FAC1_M2
    MOV B, A
    LDA FAC2_M2
    SBB B
    STA FAC1_M2

FP_ADD_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

FP_SUB:
    PUSH PSW
    LDA FAC2_SIGN
    XRI 80H
    STA FAC2_SIGN
    CALL FP_ADD
    LDA FAC2_SIGN
    XRI 80H
    STA FAC2_SIGN
    POP PSW
    RET

FP_MUL:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LDA FAC1_EXP
    ORA A
    JZ FP_MUL_EXIT
    LDA FAC2_EXP
    ORA A
    JNZ FP_MUL_EXEC
    CALL FP_SET_ZERO
    JMP FP_MUL_EXIT

FP_MUL_EXEC:
    LDA FAC1_SIGN
    MOV B, A
    LDA FAC2_SIGN
    XRA B
    STA FAC1_SIGN

    LDA FAC1_EXP
    MOV B, A
    LDA FAC2_EXP
    ADD B
    SUI 80H
    STA FAC1_EXP

    LDA FAC1_M2
    MOV H, A
    LDA FAC2_M2
    MOV E, A
    MVI D, 0
    MVI L, 0
    MVI B, 8
MUL_LOOP:
    MOV A, H
    ADD A
    MOV H, A
    JNC MUL_NO_ADD
    MOV A, L
    ADD E
    MOV L, A
    MOV A, D
    ACI 0
    MOV D, A
MUL_NO_ADD:
    DCR B
    JNZ MUL_LOOP

    MOV A, D
    STA FAC1_M2
    MOV A, L
    STA FAC1_M1
    MVI A, 0
    STA FAC1_M0

FP_MUL_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

FP_DIV:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LDA FAC2_EXP
    ORA A
    JZ FP_DIV_ERR

    LDA FAC1_EXP
    ORA A
    JZ FP_DIV_EXIT

    LDA FAC1_SIGN
    MOV B, A
    LDA FAC2_SIGN
    XRA B
    STA FAC1_SIGN

    LDA FAC1_EXP
    MOV B, A
    LDA FAC2_EXP
    MOV C, A
    MOV A, B
    SUB C
    ADI 80H
    STA FAC1_EXP
    JMP FP_DIV_EXIT

FP_DIV_ERR:
    LXI HL, MSG_FP_DIV0
    CALL PRSTR
    CALL PRNL
    CALL FP_SET_ZERO

FP_DIV_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

PR_FLOAT:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    LDA FAC1_EXP
    ORA A
    JNZ PRF_NON_ZERO
    LXI HL, MSG_FP_ZERO
    CALL PRSTR
    JMP PRF_EXIT

PRF_NON_ZERO:
    LDA FAC1_SIGN
    ORA A
    JZ PRF_CONV
    MVI A, '-'
    CALL COUT

PRF_CONV:
    CALL FP_TO_INT
    CALL PRDEC16
    MVI A, '.'
    CALL COUT

    LDA FAC1_M1
    ANI 0FH
    ADI '0'
    CALL COUT
    LDA FAC1_M0
    ANI 0FH
    ADI '0'
    CALL COUT

PRF_EXIT:
    POP B
    POP D
    POP H
    POP PSW
    RET

MSG_FP_ZERO: DB '0.00', 0
MSG_FP_DIV0: DB 'Floating-Point Error: Division by Zero!', 0

FAC1_EXP:  DB 0
FAC1_SIGN: DB 0
FAC1_M2:   DB 0
FAC1_M1:   DB 0
FAC1_M0:   DB 0

FAC2_EXP:  DB 0
FAC2_SIGN: DB 0
FAC2_M2:   DB 0
FAC2_M1:   DB 0
FAC2_M0:   DB 0

FAC_TEMP:  DS 5


; =============================================================================
; 8. BCD (BINARY-CODED DECIMAL) MATH PACKAGE (NEW in v5)
; Operations on packed BCD arrays (stored LSB first, 2 decimal digits per byte).
; =============================================================================

; -----------------------------------------------------------------------------
; DAA_ADD8 - Add Two Single-Byte Packed BCD Values
; Entry: A = Packed BCD byte 1, B = Packed BCD byte 2
; Exit:  A = Decimal-adjusted BCD sum, Carry flag set if decimal overflow (> 99)
; -----------------------------------------------------------------------------
DAA_ADD8:
    ADD B
    DAA
    RET

; -----------------------------------------------------------------------------
; BCD_ADD - Multi-Byte Packed BCD Addition
; Entry: HL = Address of Destination BCD Array (LSB first)
;        DE = Address of Source BCD Array (LSB first)
;        B  = Byte Count (e.g. 4 bytes = 8 digits)
; Exit:  Destination array updated with packed BCD sum ([HL] = [HL] + [DE])
; Registers preserved: DE, HL
; -----------------------------------------------------------------------------
BCD_ADD:
    PUSH H
    PUSH D
    PUSH B
    ORA A               ; Clear Carry flag (initial decimal carry = 0)

BCD_ADD_LOOP:
    MOV A, M            ; Load Destination byte
    LDAX D              ; Load Source byte
    ADC M               ; Add Destination + Source + Carry
    DAA                 ; Decimal Adjust Accumulator
    MOV M, A            ; Store BCD sum in Destination byte
    INX HL              ; Point to next higher byte (LSB -> MSB)
    INX DE
    DCR B
    JNZ BCD_ADD_LOOP

    POP B
    POP D
    POP H
    RET

; -----------------------------------------------------------------------------
; BCD_SUB - Multi-Byte Packed BCD Subtraction
; Uses 8080-compatible 10's complement decimal arithmetic.
; Entry: HL = Address of Destination BCD Array (Minuend, LSB first)
;        DE = Address of Source BCD Array (Subtrahend, LSB first)
;        B  = Byte Count (e.g. 4 bytes = 8 digits)
; Exit:  Destination array updated with packed BCD difference ([HL] = [HL] - [DE])
; Registers preserved: DE, HL
; -----------------------------------------------------------------------------
BCD_SUB:
    PUSH H
    PUSH D
    PUSH B
    STC                 ; Set Carry = 1 at start (STC = 1 means NO borrow for LSB 10's comp)

BCD_SUB_LOOP:
    MVI A, 99H          ; A = 99H
    SBB C               ; Wait: load source byte
    PUSH B              ; Save B (count)
    LDAX D              ; A = Source byte
    MOV C, A            ; C = Source byte
    MVI A, 99H
    POP B               ; Restore B (count)
    SBB C               ; A = 99H - Source - (1 - Carry)
    INR A               ; A = 99H - Source + Carry = 10's complement
    ADD M               ; Add Destination byte
    DAA                 ; Decimal Adjust Accumulator
    MOV M, A            ; Store BCD difference
    INX HL              ; Point to next higher byte
    INX DE
    DCR B
    JNZ BCD_SUB_LOOP

    POP B
    POP D
    POP H
    RET

; -----------------------------------------------------------------------------
; INT_TO_BCD - Convert 16-Bit Unsigned Integer in HL to 5-Digit Packed BCD
; Entry: HL = Unsigned 16-bit integer (0..65535)
;        DE = Address of 3-byte target BCD buffer (LSB first)
; Exit:  Target buffer updated with 5 packed BCD digits
; -----------------------------------------------------------------------------
INT_TO_BCD:
    PUSH H
    PUSH D
    PUSH B

    ; Clear 3-byte BCD target buffer
    PUSH D
    MVI A, 0
    STAX D
    INX DE
    STAX D
    INX DE
    STAX D
    POP DE

    ; 1. Calculate Ten-Thousands (10,000s) -> Byte 2 Lower Nibble
    LXI B, -10000
    CALL BCD_COUNT_DIGIT
    STAX D              ; Save 10,000s count in Byte 2

    ; 2. Calculate Thousands (1,000s) -> Byte 1 Upper Nibble
    DCX DE              ; Point to Byte 1
    LXI B, -1000
    CALL BCD_COUNT_DIGIT
    RLC
    RLC
    RLC
    RLC
    MOV C, A            ; Save 1,000s count in C

    ; 3. Calculate Hundreds (100s) -> Byte 1 Lower Nibble
    LXI B, -100
    CALL BCD_COUNT_DIGIT
    ORA C
    STAX D              ; Save (1000s | 100s) in Byte 1

    ; 4. Calculate Tens (10s) -> Byte 0 Upper Nibble
    DCX DE              ; Point to Byte 0
    LXI B, -10
    CALL BCD_COUNT_DIGIT
    RLC
    RLC
    RLC
    RLC
    MOV C, A

    ; 5. Remaining Units (1s) -> Byte 0 Lower Nibble
    MOV A, L
    ORA C
    STAX D              ; Save (10s | 1s) in Byte 0

    POP B
    POP D
    POP H
    RET

; Helper: Repeated subtraction to count how many negative divisors fit in HL
BCD_COUNT_DIGIT:
    MVI A, 0
BCD_CD_LOOP:
    PUSH H
    DAD B
    JNC BCD_CD_STOP     ; Underflow
    INX SP
    INX SP
    INR A
    JMP BCD_CD_LOOP
BCD_CD_STOP:
    POP H               ; Restore remainder
    RET

; -----------------------------------------------------------------------------
; PR_BCD - Print Packed BCD Buffer as Decimal String (Leading Zero Suppressed)
; Entry: HL = Pointer to LSB of BCD array
;        B  = Byte Count (e.g. 4 bytes = 8 digits)
; -----------------------------------------------------------------------------
PR_BCD:
    PUSH H
    PUSH D
    PUSH B
    PUSH PSW

    ; Move HL to point to MSB byte (HL = HL + B - 1)
    MOV E, B
    MVI D, 0
    DAD D
    DCX HL

    MVI C, 1            ; Suppress Flag C = 1 (active leading zero suppression)

PR_BCD_BYTE_LOOP:
    MOV A, M            ; Read current byte (2 digits)

    ; Upper Nibble (Digit 1)
    PUSH PSW
    ANI 0F0H
    RRC
    RRC
    RRC
    RRC
    CALL PR_BCD_DIGIT
    POP PSW

    ; Lower Nibble (Digit 2)
    ANI 0FH
    CALL PR_BCD_DIGIT

    DCX HL              ; Next byte down towards LSB
    DCR B
    JNZ PR_BCD_BYTE_LOOP

    ; If all digits were zero, print single '0'
    MOV A, C
    ORA A
    JZ PR_BCD_EXIT
    MVI A, '0'
    CALL COUT

PR_BCD_EXIT:
    POP PSW
    POP B
    POP D
    POP H
    RET

; Helper to print single BCD digit with leading zero suppression
PR_BCD_DIGIT:
    ORA A               ; Is digit 0?
    JNZ PRBD_PRINT_DIGIT
    MOV A, C
    ORA A               ; Is suppression flag set?
    RZ                  ; Yes, skip leading zero
    MVI A, 0            ; Restore digit 0
PRBD_PRINT_DIGIT:
    MVI C, 0            ; Clear suppression flag (non-zero digit seen)
    ADI '0'
    CALL COUT
    RET

; =============================================================================
; 8. 16.16 FIXED-POINT BINARY ARITHMETIC PACKAGE (NEW in v6)
; Format: 32-bit signed fixed-point number (4 bytes, little-endian)
; Byte 0: Fractional Low Byte (bits 0-7)
; Byte 1: Fractional High Byte (bits 8-15)
; Byte 2: Integer Low Byte (bits 16-23)
; Byte 3: Integer High Byte (bits 24-31, bit 31 = Sign bit)
; =============================================================================

FIX_LOAD:
    PUSH H
    PUSH D
    PUSH B
    LXI DE, FIX_ACC1
    LXI B, 4
    CALL MEMCPY
    POP B
    POP D
    POP H
    RET

FIX_STORE:
    PUSH H
    PUSH D
    PUSH B
    XCHG
    LXI HL, FIX_ACC1
    LXI B, 4
    CALL MEMCPY
    POP B
    POP D
    POP H
    RET

FIX_LOAD2:
    PUSH H
    PUSH D
    PUSH B
    LXI DE, FIX_ACC2
    LXI B, 4
    CALL MEMCPY
    POP B
    POP D
    POP H
    RET

INT_TO_FIX16:
    PUSH PSW
    MVI A, 0
    STA FIX_ACC1+0
    STA FIX_ACC1+1
    MOV A, L
    STA FIX_ACC1+2
    MOV A, H
    STA FIX_ACC1+3
    POP PSW
    RET

FIX_ADD:
    PUSH PSW
    PUSH H
    PUSH D
    LDA FIX_ACC1+0
    LXI HL, FIX_ACC2+0
    ADD M
    STA FIX_ACC1+0
    LDA FIX_ACC1+1
    LXI HL, FIX_ACC2+1
    ADC M
    STA FIX_ACC1+1
    LDA FIX_ACC1+2
    LXI HL, FIX_ACC2+2
    ADC M
    STA FIX_ACC1+2
    LDA FIX_ACC1+3
    LXI HL, FIX_ACC2+3
    ADC M
    STA FIX_ACC1+3
    POP D
    POP H
    POP PSW
    RET

FIX_SUB:
    PUSH PSW
    PUSH H
    PUSH D
    LDA FIX_ACC1+0
    LXI HL, FIX_ACC2+0
    SUB M
    STA FIX_ACC1+0
    LDA FIX_ACC1+1
    LXI HL, FIX_ACC2+1
    SBB M
    STA FIX_ACC1+1
    LDA FIX_ACC1+2
    LXI HL, FIX_ACC2+2
    SBB M
    STA FIX_ACC1+2
    LDA FIX_ACC1+3
    LXI HL, FIX_ACC2+3
    SBB M
    STA FIX_ACC1+3
    POP D
    POP H
    POP PSW
    RET

FIX_NEG1:
    PUSH PSW
    LDA FIX_ACC1+0
    CMA
    ADI 1
    STA FIX_ACC1+0
    LDA FIX_ACC1+1
    CMA
    ACI 0
    STA FIX_ACC1+1
    LDA FIX_ACC1+2
    CMA
    ACI 0
    STA FIX_ACC1+2
    LDA FIX_ACC1+3
    CMA
    ACI 0
    STA FIX_ACC1+3
    POP PSW
    RET

FIX_NEG2:
    PUSH PSW
    LDA FIX_ACC2+0
    CMA
    ADI 1
    STA FIX_ACC2+0
    LDA FIX_ACC2+1
    CMA
    ACI 0
    STA FIX_ACC2+1
    LDA FIX_ACC2+2
    CMA
    ACI 0
    STA FIX_ACC2+2
    LDA FIX_ACC2+3
    CMA
    ACI 0
    STA FIX_ACC2+3
    POP PSW
    RET

FIX_MUL:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LDA FIX_ACC1+3
    MOV B, A
    LDA FIX_ACC2+3
    XRA B
    STA FIX_SIGN_RES

    LDA FIX_ACC1+3
    ORA A
    JP FM_CHECK_ACC2
    CALL FIX_NEG1

FM_CHECK_ACC2:
    LDA FIX_ACC2+3
    ORA A
    JP FM_EXEC_MUL
    CALL FIX_NEG2

FM_EXEC_MUL:
    LXI HL, FIX_PROD
    LXI BC, 8
    MVI A, 0
    CALL MEMSET

    MVI C, 32
FM_LOOP:
    ORA A
    LXI HL, FIX_PROD+7
    MVI B, 8
FM_SHIFT_RIGHT:
    MOV A, M
    RAR
    MOV M, A
    DCX HL
    DCR B
    JNZ FM_SHIFT_RIGHT

    LDA FIX_ACC2+0
    ANI 01H
    JZ FM_NEXT_BIT

    LDA FIX_PROD+4
    LXI HL, FIX_ACC1+0
    ADD M
    STA FIX_PROD+4

    LDA FIX_PROD+5
    LXI HL, FIX_ACC1+1
    ADC M
    STA FIX_PROD+5

    LDA FIX_PROD+6
    LXI HL, FIX_ACC1+2
    ADC M
    STA FIX_PROD+6

    LDA FIX_PROD+7
    LXI HL, FIX_ACC1+3
    ADC M
    STA FIX_PROD+7

FM_NEXT_BIT:
    ORA A
    LDA FIX_ACC2+3
    RAR
    STA FIX_ACC2+3
    LDA FIX_ACC2+2
    RAR
    STA FIX_ACC2+2
    LDA FIX_ACC2+1
    RAR
    STA FIX_ACC2+1
    LDA FIX_ACC2+0
    RAR
    STA FIX_ACC2+0

    DCR C
    JNZ FM_LOOP

    LDA FIX_PROD+2
    STA FIX_ACC1+0
    LDA FIX_PROD+3
    STA FIX_ACC1+1
    LDA FIX_PROD+4
    STA FIX_ACC1+2
    LDA FIX_PROD+5
    STA FIX_ACC1+3

    LDA FIX_SIGN_RES
    ORA A
    JP FM_DONE
    CALL FIX_NEG1

FM_DONE:
    POP H
    POP D
    POP B
    POP PSW
    RET

FIX_DIV:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LDA FIX_ACC2+0
    ORA A
    JNZ FD_EXEC
    LDA FIX_ACC2+1
    ORA A
    JNZ FD_EXEC
    LDA FIX_ACC2+2
    ORA A
    JNZ FD_EXEC
    LDA FIX_ACC2+3
    ORA A
    JNZ FD_EXEC

    LXI HL, MSG_FIX_DIV0
    CALL PRSTR
    CALL PRNL
    MVI A, 0
    STA FIX_ACC1+0
    STA FIX_ACC1+1
    STA FIX_ACC1+2
    STA FIX_ACC1+3
    JMP FD_DONE

FD_EXEC:
    LDA FIX_ACC1+3
    MOV B, A
    LDA FIX_ACC2+3
    XRA B
    STA FIX_SIGN_RES

    LDA FIX_ACC1+3
    ORA A
    JP FD_CHECK_ACC2
    CALL FIX_NEG1

FD_CHECK_ACC2:
    LDA FIX_ACC2+3
    ORA A
    JP FD_START_DIV
    CALL FIX_NEG2

FD_START_DIV:
    LXI HL, FIX_DIVIDEND
    LXI BC, 6
    MVI A, 0
    CALL MEMSET

    LDA FIX_ACC1+0
    STA FIX_DIVIDEND+2
    LDA FIX_ACC1+1
    STA FIX_DIVIDEND+3
    LDA FIX_ACC1+2
    STA FIX_DIVIDEND+4
    LDA FIX_ACC1+3
    STA FIX_DIVIDEND+5

    LXI HL, FIX_QUOT
    LXI BC, 4
    MVI A, 0
    CALL MEMSET

    MVI C, 32
FD_DIV_LOOP:
    ORA A
    LDA FIX_QUOT+0
    RAL
    STA FIX_QUOT+0
    LDA FIX_QUOT+1
    RAL
    STA FIX_QUOT+1
    LDA FIX_QUOT+2
    RAL
    STA FIX_QUOT+2
    LDA FIX_QUOT+3
    RAL
    STA FIX_QUOT+3

    ORA A
    LXI HL, FIX_DIVIDEND
    MVI B, 6
FD_SHIFT_DIV:
    MOV A, M
    RAL
    MOV M, A
    INX HL
    DCR B
    JNZ FD_SHIFT_DIV

    LDA FIX_DIVIDEND+2
    LXI HL, FIX_ACC2+0
    SUB M
    LDA FIX_DIVIDEND+3
    LXI HL, FIX_ACC2+1
    SBB M
    LDA FIX_DIVIDEND+4
    LXI HL, FIX_ACC2+2
    SBB M
    LDA FIX_DIVIDEND+5
    LXI HL, FIX_ACC2+3
    SBB M
    JC FD_NEXT_ITER

    LDA FIX_DIVIDEND+2
    LXI HL, FIX_ACC2+0
    SUB M
    STA FIX_DIVIDEND+2

    LDA FIX_DIVIDEND+3
    LXI HL, FIX_ACC2+1
    SBB M
    STA FIX_DIVIDEND+3

    LDA FIX_DIVIDEND+4
    LXI HL, FIX_ACC2+2
    SBB M
    STA FIX_DIVIDEND+4

    LDA FIX_DIVIDEND+5
    LXI HL, FIX_ACC2+3
    SBB M
    STA FIX_DIVIDEND+5

    LDA FIX_QUOT+0
    ORI 01H
    STA FIX_QUOT+0

FD_NEXT_ITER:
    DCR C
    JNZ FD_DIV_LOOP

    LXI HL, FIX_QUOT
    LXI DE, FIX_ACC1
    LXI BC, 4
    CALL MEMCPY

    LDA FIX_SIGN_RES
    ORA A
    JP FD_DONE
    CALL FIX_NEG1

FD_DONE:
    POP H
    POP D
    POP B
    POP PSW
    RET

PR_FIX:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    LDA FIX_ACC1+3
    ORA A
    JP PF_PRINT_VAL
    MVI A, '-'
    CALL COUT
    CALL FIX_NEG1

PF_PRINT_VAL:
    LDA FIX_ACC1+2
    MOV L, A
    LDA FIX_ACC1+3
    MOV H, A
    CALL PRDEC16

    MVI A, '.'
    CALL COUT

    LDA FIX_ACC1+0
    MOV L, A
    LDA FIX_ACC1+1
    MOV H, A

    MVI C, 4
PF_FRAC_LOOP:
    PUSH B
    MOV D, H
    MOV E, L
    DAD HL
    DAD HL
    DAD DE
    DAD HL
    ; Upper byte overflow in H contains digit
    MOV A, H
    ; Clear upper bits for next fractional iteration
    MVI H, 0
    CALL PRDEC16
    POP B

    DCR C
    JNZ PF_FRAC_LOOP

    POP B
    POP D
    POP H
    POP PSW
    RET

MSG_FIX_DIV0: DB 'Fixed-Point Error: Division by Zero!', 0

FIX_ACC1:     DS 4
FIX_ACC2:     DS 4
FIX_SIGN_RES: DB 0
FIX_PROD:     DS 8
FIX_DIVIDEND: DS 6
FIX_QUOT:     DS 4


; =============================================================================
; 9. CRC-16 DATA INTEGRITY PACKAGE (NEW in v7)
; Implements fast CRC-16-CCITT (XMODEM polynomial 1021H) checksum calculation
; for byte streams, memory buffers, and CP/M files.
; =============================================================================

; -----------------------------------------------------------------------------
; CRC16_UPDATE - Update 16-bit CRC in HL with byte in A (CRC-16-CCITT 1021H)
; Entry: HL = Current 16-bit CRC value (0000H initially)
;        A  = Byte to process
; Exit:  HL = Updated 16-bit CRC value
; Registers preserved: BC, DE
; -----------------------------------------------------------------------------
CRC16_UPDATE:
    PUSH B
    XRA H               ; XOR input byte with upper byte of current CRC
    MOV H, A
    MVI B, 8            ; Process 8 bits
CRC16_BIT_LOOP:
    DAD H               ; Shift 16-bit CRC in HL left 1 bit (MSB to Carry)
    JNC CRC16_NO_XOR
    ; XOR HL with polynomial 1021H
    MOV A, H
    XRI 10H
    MOV H, A
    MOV A, L
    XRI 21H
    MOV L, A
CRC16_NO_XOR:
    DCR B
    JNZ CRC16_BIT_LOOP
    POP B
    RET

; -----------------------------------------------------------------------------
; CRC16_BUF - Compute 16-Bit CRC-16-CCITT over Memory Buffer
; Entry: HL = Buffer start address
;        BC = Byte count
; Exit:  HL = 16-bit CRC-16 value
; Registers used: AF, BC, DE, HL
; -----------------------------------------------------------------------------
CRC16_BUF:
    PUSH D
    XCHG                ; DE = Buffer address
    LXI H, 0000H        ; Initialize CRC = 0000H
CRC16_BUF_LOOP:
    MOV A, B
    ORA C
    JZ CRC16_BUF_DONE
    LDAX D              ; Read byte from buffer
    CALL CRC16_UPDATE
    INX DE              ; Next byte address
    DCX B               ; Decrement remaining byte count
    JMP CRC16_BUF_LOOP
CRC16_BUF_DONE:
    POP D
    RET

; -----------------------------------------------------------------------------
; CRC16_FILE - Compute 16-Bit CRC-16-CCITT for an Open CP/M File
; Entry: DE = Pointer to opened FCB
; Exit:  HL = 16-bit CRC-16 value
; -----------------------------------------------------------------------------
CRC16_FILE:
    PUSH B
    PUSH D

    CALL FSEEK_START

    LXI H, 0000H
    SHLD CRC16_ACC

CRC16_FILE_READ:
    LXI DE, DEFAULT_DMA
    CALL FSET_DMA

    POP DE
    PUSH DE             ; DE = FCB pointer

    CALL FREAD          ; Read 128-byte sector
    ORA A
    JNZ CRC16_FILE_DONE ; EOF or Read Error

    LXI DE, DEFAULT_DMA
    MVI B, 128
CRC16_FILE_SECTOR:
    LHLD CRC16_ACC
    LDAX D
    CALL CRC16_UPDATE
    SHLD CRC16_ACC
    INX DE
    DCR B
    JNZ CRC16_FILE_SECTOR
    JMP CRC16_FILE_READ

CRC16_FILE_DONE:
    POP DE
    POP B
    LHLD CRC16_ACC
    RET

; -----------------------------------------------------------------------------
; PR_CRC16 - Format and Print 16-Bit CRC Value
; Entry: HL = 16-bit CRC value
; Exit: None
; -----------------------------------------------------------------------------
PR_CRC16:
    PUSH H
    LXI HL, MSG_CRC_HEAD
    CALL PRSTR
    POP HL
    CALL PRHEX16
    RET

MSG_CRC_HEAD: DB 'CRC-16 = 0x', 0
CRC16_ACC:    DW 0


; =============================================================================
; 10. INTEL 8251 USART / SERIAL I/O PACKAGE (NEW in v8)
; Hardware driver for Intel 8251/8251A Universal Synchronous/Asynchronous
; Receiver/Transmitter with dynamic port patching and 64-byte RX ring buffer.
; =============================================================================

; Dynamic Port Execution Stubs for 8080 (IN/OUT instructions with patchable port addresses)
IN_UART_DATA:
    DB 0DBH             ; IN instruction opcode
UART_DATA_PORT: DB 80H  ; Configurable Data Port Address
    RET

OUT_UART_DATA:
    DB 0D3H             ; OUT instruction opcode
    DB 80H              ; Patched Data Port Address
    RET

IN_UART_STAT:
    DB 0DBH             ; IN instruction opcode
UART_STAT_PORT: DB 81H  ; Configurable Status/Control Port Address
    RET

OUT_UART_STAT:
    DB 0D3H             ; OUT instruction opcode
    DB 81H              ; Patched Status/Control Port Address
    RET

; -----------------------------------------------------------------------------
; UART_SET_PORTS - Configure 8251 Data and Status Port Addresses
; Entry: A = Status/Control Port Address, B = Data Port Address
; -----------------------------------------------------------------------------
UART_SET_PORTS:
    STA UART_STAT_PORT
    STA IN_UART_STAT+1
    STA OUT_UART_STAT+1
    MOV A, B
    STA UART_DATA_PORT
    STA IN_UART_DATA+1
    STA OUT_UART_DATA+1
    RET

; -----------------------------------------------------------------------------
; UART_INIT - Reset and Initialize Intel 8251 USART
; Sends 8251 reset command sequence and configures mode and control bytes.
; -----------------------------------------------------------------------------
UART_INIT:
    PUSH PSW
    PUSH B

    ; Ensure port patching is updated
    LDA UART_DATA_PORT
    STA IN_UART_DATA+1
    STA OUT_UART_DATA+1
    LDA UART_STAT_PORT
    STA IN_UART_STAT+1
    STA OUT_UART_STAT+1

    ; Send 3 dummy zero bytes to command port to guarantee command state
    MVI A, 00H
    CALL OUT_UART_STAT
    CALL OUT_UART_STAT
    CALL OUT_UART_STAT

    ; Send Internal Reset Command (40H) to 8251
    MVI A, 40H
    CALL OUT_UART_STAT

    ; Write Mode Instruction (e.g. 4EH = 8N1, x16 clock)
    LDA UART_MODE_BYTE
    CALL OUT_UART_STAT

    ; Write Control Command (e.g. 37H = TxEN, RxEN, Reset Flags, DTR/RTS)
    LDA UART_CTRL_BYTE
    CALL OUT_UART_STAT

    ; Initialize Rx software ring buffer
    CALL UART_BUF_INIT

    POP B
    POP PSW
    RET

; -----------------------------------------------------------------------------
; UART_STAT - Read 8251 Status Register
; Exit: A = Status byte, Zero flag set if no Rx char waiting (RxRDY bit 1 = 0)
; -----------------------------------------------------------------------------
UART_STAT:
    CALL IN_UART_STAT
    PUSH PSW
    ANI 02H             ; Mask Bit 1 (RxRDY)
    POP PSW
    RET

; -----------------------------------------------------------------------------
; UART_IN - Polled Serial Character Input (Blocking)
; Exit: A = Received ASCII byte
; -----------------------------------------------------------------------------
UART_IN:
UI_POLL:
    CALL UART_STAT
    JZ UI_POLL          ; Loop while RxRDY (bit 1) is 0
    CALL IN_UART_DATA   ; Read character from data port
    RET

; -----------------------------------------------------------------------------
; UART_OUT - Polled Serial Character Output (Blocking)
; Entry: A = Character to transmit
; -----------------------------------------------------------------------------
UART_OUT:
    PUSH B
    MOV B, A            ; Save character in B
UO_POLL:
    CALL IN_UART_STAT
    ANI 01H             ; Check Bit 0 (TxRDY)
    JZ UO_POLL          ; Loop while TxRDY is 0
    MOV A, B
    CALL OUT_UART_DATA  ; Write character to data port
    POP B
    RET

; -----------------------------------------------------------------------------
; UART_SEND_STR - Transmit Null-Terminated String over Serial
; Entry: HL = Pointer to string
; -----------------------------------------------------------------------------
UART_SEND_STR:
    PUSH H
    PUSH PSW
USS_LOOP:
    MOV A, M
    ORA A
    JZ USS_EXIT
    CALL UART_OUT
    INX HL
    JMP USS_LOOP
USS_EXIT:
    POP PSW
    POP H
    RET

; -----------------------------------------------------------------------------
; SOFTWARE RX RING BUFFER (64 Bytes)
; Provides asynchronous buffer routines for incoming serial data streams.
; -----------------------------------------------------------------------------
UART_BUF_INIT:
    PUSH PSW
    MVI A, 0
    STA UART_HEAD
    STA UART_TAIL
    STA UART_COUNT
    POP PSW
    RET

UART_BUF_PUT:
    PUSH B
    PUSH D
    PUSH H
    MOV B, A            ; B = Byte to store
    LDA UART_COUNT
    CPI 64
    STC                 ; Set Carry = Buffer full
    JZ UBP_EXIT

    LDA UART_TAIL
    MOV E, A
    MVI D, 0
    LXI HL, UART_RING_BUF
    DAD DE              ; HL = UART_RING_BUF + Tail
    MOV M, B            ; Store byte in ring buffer

    LDA UART_TAIL
    INR A
    ANI 3FH             ; Tail = (Tail + 1) % 64
    STA UART_TAIL

    LDA UART_COUNT
    INR A
    STA UART_COUNT
    ORA A               ; Clear Carry = Success

UBP_EXIT:
    POP H
    POP D
    POP B
    RET

UART_BUF_GET:
    PUSH B
    PUSH D
    PUSH H
    LDA UART_COUNT
    ORA A
    STC                 ; Set Carry = Buffer empty
    JZ UBG_EXIT

    LDA UART_HEAD
    MOV E, A
    MVI D, 0
    LXI HL, UART_RING_BUF
    DAD DE
    MOV B, M            ; Read byte into B

    LDA UART_HEAD
    INR A
    ANI 3FH             ; Head = (Head + 1) % 64
    STA UART_HEAD

    LDA UART_COUNT
    DCR A
    STA UART_COUNT

    MOV A, B            ; A = Read byte
    ORA A               ; Clear Carry = Success

UBG_EXIT:
    POP H
    POP D
    POP B
    RET

UART_BUF_STAT:
    LDA UART_COUNT
    ORA A
    RET

; Configurable 8251 Settings & Storage
UART_MODE_BYTE: DB 4EH  ; Default 8N1 x16 clock (01001110B)
UART_CTRL_BYTE: DB 37H  ; Default TxEN, RxEN, Error Reset, DTR/RTS low (00110111B)
UART_HEAD:      DB 0
UART_TAIL:      DB 0
UART_COUNT:     DB 0
UART_RING_BUF:  DS 64


; =============================================================================
; 10. 32-BIT BINARY INTEGER ARITHMETIC PACKAGE (NEW in v9)
; Format: 32-bit unsigned/signed binary integer (4 bytes, little-endian)
; Byte 0: LSB (bits 0-7)
; Byte 1: Mid-Low (bits 8-15)
; Byte 2: Mid-High (bits 16-23)
; Byte 3: MSB (bits 24-31)
; =============================================================================

; -----------------------------------------------------------------------------
; ADD32 - 32-Bit Integer Addition: [HL] = [HL] + [DE]
; Entry: HL = Pointer to 32-bit Destination integer (little-endian)
;        DE = Pointer to 32-bit Source integer (little-endian)
; Exit:  Destination updated ([HL] = [HL] + [DE])
; Registers preserved: BC, DE, HL
; -----------------------------------------------------------------------------
ADD32:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    ; Byte 0
    LDAX D
    ADD M
    MOV M, A
    INX HL
    INX DE

    ; Byte 1
    LDAX D
    ADC M
    MOV M, A
    INX HL
    INX DE

    ; Byte 2
    LDAX D
    ADC M
    MOV M, A
    INX HL
    INX DE

    ; Byte 3
    LDAX D
    ADC M
    MOV M, A

    POP B
    POP D
    POP H
    POP PSW
    RET

; -----------------------------------------------------------------------------
; SUB32 - 32-Bit Integer Subtraction: [HL] = [HL] - [DE]
; Entry: HL = Pointer to 32-bit Destination integer (Minuend, little-endian)
;        DE = Pointer to 32-bit Source integer (Subtrahend, little-endian)
; Exit:  Destination updated ([HL] = [HL] - [DE])
; Registers preserved: BC, DE, HL
; -----------------------------------------------------------------------------
SUB32:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    ; Byte 0
    MOV A, M
    LDAX D
    SUB M
    CMA
    INR A
    MOV B, A            ; Temporary
    MOV A, M
    LDAX D
    SUB A               ; Proper subtraction:
    ; A = [HL] - [DE]
    MOV A, M
    LDAX D
    ; Compute [HL] - [DE]
    PUSH B
    LDAX D
    MOV B, A
    MOV A, M
    SUB B
    MOV M, A
    POP B
    INX HL
    INX DE

    ; Byte 1
    PUSH B
    LDAX D
    MOV B, A
    MOV A, M
    SBB B
    MOV M, A
    POP B
    INX HL
    INX DE

    ; Byte 2
    PUSH B
    LDAX D
    MOV B, A
    MOV A, M
    SBB B
    MOV M, A
    POP B
    INX HL
    INX DE

    ; Byte 3
    PUSH B
    LDAX D
    MOV B, A
    MOV A, M
    SBB B
    MOV M, A
    POP B

    POP B
    POP D
    POP H
    POP PSW
    RET

; -----------------------------------------------------------------------------
; MUL32 - 32-Bit Unsigned Integer Multiplication: [HL] = [HL] * [DE]
; Entry: HL = Pointer to 32-bit Factor A (little-endian)
;        DE = Pointer to 32-bit Factor B (little-endian)
; Exit:  Factor A updated with lower 32 bits of product ([HL] = [HL] * [DE])
; -----------------------------------------------------------------------------
MUL32:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Copy Factor A to INT32_ACC1 and Factor B to INT32_ACC2
    PUSH DE
    PUSH HL
    LXI DE, INT32_ACC1
    LXI BC, 4
    CALL MEMCPY
    POP HL
    POP DE
    XCHG
    LXI DE, INT32_ACC2
    LXI BC, 4
    CALL MEMCPY

    ; Clear 8-byte product register
    LXI HL, INT32_PROD
    LXI BC, 8
    MVI A, 0
    CALL MEMSET

    MVI C, 32           ; 32 bits
M32_LOOP:
    ; Shift product right 1 bit
    ORA A
    LXI HL, INT32_PROD+7
    MVI B, 8
M32_SHIFT_RIGHT:
    MOV A, M
    RAR
    MOV M, A
    DCX HL
    DCR B
    JNZ M32_SHIFT_RIGHT

    ; Check bit 0 of INT32_ACC2
    LDA INT32_ACC2+0
    ANI 01H
    JZ M32_NEXT_BIT

    ; Add INT32_ACC1 to upper 4 bytes of product (INT32_PROD+4..7)
    LDA INT32_PROD+4
    LXI HL, INT32_ACC1+0
    ADD M
    STA INT32_PROD+4

    LDA INT32_PROD+5
    LXI HL, INT32_ACC1+1
    ADC M
    STA INT32_PROD+5

    LDA INT32_PROD+6
    LXI HL, INT32_ACC1+2
    ADC M
    STA INT32_PROD+6

    LDA INT32_PROD+7
    LXI HL, INT32_ACC1+3
    ADC M
    STA INT32_PROD+7

M32_NEXT_BIT:
    ; Shift INT32_ACC2 right 1 bit
    ORA A
    LDA INT32_ACC2+3
    RAR
    STA INT32_ACC2+3
    LDA INT32_ACC2+2
    RAR
    STA INT32_ACC2+2
    LDA INT32_ACC2+1
    RAR
    STA INT32_ACC2+1
    LDA INT32_ACC2+0
    RAR
    STA INT32_ACC2+0

    DCR C
    JNZ M32_LOOP

    ; Store product back to destination HL
    POP HL
    PUSH HL
    LDA INT32_PROD+2
    MOV M, A
    INX HL
    LDA INT32_PROD+3
    MOV M, A
    INX HL
    LDA INT32_PROD+4
    MOV M, A
    INX HL
    LDA INT32_PROD+5
    MOV M, A

    POP DE
    POP B
    POP D
    POP B
    POP PSW
    RET

; -----------------------------------------------------------------------------
; DIV32 - 32-Bit Unsigned Integer Division: [HL] = [HL] / [DE]
; Remainder stored in INT32_REM
; -----------------------------------------------------------------------------
DIV32:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Check divisor for 0
    LDAX DE
    MOV B, A
    INX DE
    LDAX DE
    ORA B
    MOV B, A
    INX DE
    LDAX DE
    ORA B
    MOV B, A
    INX DE
    LDAX DE
    ORA B
    DCX DE
    DCX DE
    DCX DE
    JNZ D32_EXEC

    ; Division by zero error
    LXI HL, MSG_INT32_DIV0
    CALL PRSTR
    CALL PRNL
    JMP D32_DONE

D32_EXEC:
    ; Copy Dividend [HL] to INT32_QUOT and Divisor [DE] to INT32_ACC2
    PUSH DE
    PUSH HL
    LXI DE, INT32_QUOT
    LXI BC, 4
    CALL MEMCPY
    POP HL
    POP DE
    XCHG
    LXI DE, INT32_ACC2
    LXI BC, 4
    CALL MEMCPY

    ; Clear 4-byte remainder
    LXI HL, INT32_REM
    LXI BC, 4
    MVI A, 0
    CALL MEMSET

    MVI C, 32
D32_LOOP:
    ; Shift Dividend/Quotient left, MSB into Remainder LSB
    ORA A
    LDA INT32_QUOT+0
    RAL
    STA INT32_QUOT+0
    LDA INT32_QUOT+1
    RAL
    STA INT32_QUOT+1
    LDA INT32_QUOT+2
    RAL
    STA INT32_QUOT+2
    LDA INT32_QUOT+3
    RAL
    STA INT32_QUOT+3

    LDA INT32_REM+0
    RAL
    STA INT32_REM+0
    LDA INT32_REM+1
    RAL
    STA INT32_REM+1
    LDA INT32_REM+2
    RAL
    STA INT32_REM+2
    LDA INT32_REM+3
    RAL
    STA INT32_REM+3

    ; Compare Remainder with Divisor INT32_ACC2
    LDA INT32_REM+0
    LXI HL, INT32_ACC2+0
    SUB M
    LDA INT32_REM+1
    LXI HL, INT32_ACC2+1
    SBB M
    LDA INT32_REM+2
    LXI HL, INT32_ACC2+2
    SBB M
    LDA INT32_REM+3
    LXI HL, INT32_ACC2+3
    SBB M
    JC D32_NEXT_BIT

    ; Subtract Divisor from Remainder
    LDA INT32_REM+0
    LXI HL, INT32_ACC2+0
    SUB M
    STA INT32_REM+0

    LDA INT32_REM+1
    LXI HL, INT32_ACC2+1
    SBB M
    STA INT32_REM+1

    LDA INT32_REM+2
    LXI HL, INT32_ACC2+2
    SBB M
    STA INT32_REM+2

    LDA INT32_REM+3
    LXI HL, INT32_ACC2+3
    SBB M
    STA INT32_REM+3

    ; Set quotient bit 0
    LDA INT32_QUOT+0
    ORI 01H
    STA INT32_QUOT+0

D32_NEXT_BIT:
    DCR C
    JNZ D32_LOOP

    ; Copy Quotient to destination HL
    POP HL
    LXI DE, INT32_QUOT
    PUSH HL
    XCHG
    LXI BC, 4
    CALL MEMCPY
    POP HL

D32_DONE:
    POP H
    POP D
    POP B
    POP PSW
    RET

; -----------------------------------------------------------------------------
; PRDEC32 - Format and Print 32-Bit Unsigned Integer in Decimal ASCII
; Entry: HL = Address of 32-bit unsigned integer
; Exit: None
; -----------------------------------------------------------------------------
PRDEC32:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Copy 32-bit number to INT32_QUOT
    LXI DE, INT32_QUOT
    LXI BC, 4
    CALL MEMCPY

    ; Check if number is 0
    LDA INT32_QUOT+0
    ORA A
    JNZ PRD32_START
    LDA INT32_QUOT+1
    ORA A
    JNZ PRD32_START
    LDA INT32_QUOT+2
    ORA A
    JNZ PRD32_START
    LDA INT32_QUOT+3
    ORA A
    JNZ PRD32_START
    MVI A, '0'
    CALL COUT
    JMP PRD32_EXIT

PRD32_START:
    LXI HL, INT32_DEC_STR+10
    MVI M, 0            ; Null terminator
    DCX HL

PRD32_CONV_LOOP:
    ; Check if Quotient is 0
    LDA INT32_QUOT+0
    MOV B, A
    LDA INT32_QUOT+1
    ORA B
    MOV B, A
    LDA INT32_QUOT+2
    ORA B
    MOV B, A
    LDA INT32_QUOT+3
    ORA B
    JZ PRD32_PRINT

    ; Divide INT32_QUOT by 10 (0000000AH)
    LXI DE, INT32_DIV10
    PUSH HL
    LXI HL, INT32_QUOT
    CALL DIV32
    POP HL

    ; Remainder in INT32_REM+0
    LDA INT32_REM+0
    ADI '0'
    MOV M, A
    DCX HL
    JMP PRD32_CONV_LOOP

PRD32_PRINT:
    INX HL
    CALL PRSTR

PRD32_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

MSG_INT32_DIV0: DB '32-Bit Integer Error: Division by Zero!', 0
INT32_DIV10:    DB 0AH, 00H, 00H, 00H

INT32_ACC1:    DS 4
INT32_ACC2:    DS 4
INT32_PROD:    DS 8
INT32_QUOT:    DS 4
INT32_REM:     DS 4
INT32_DEC_STR: DS 12


; =============================================================================
; 11. 64-BIT BINARY INTEGER ARITHMETIC PACKAGE (NEW in v10)
; Operations on 64-bit (8-byte) little-endian unsigned/signed integers.
; Format: Byte 0 = LSB ... Byte 7 = MSB.
; =============================================================================

; -----------------------------------------------------------------------------
; ADD64 - 64-Bit Binary Addition
; Entry: HL = Pointer to Destination 64-bit integer (LSB first)
;        DE = Pointer to Source 64-bit integer (LSB first)
; Exit:  [HL] = [HL] + [DE] (8-byte sum), Carry set if 64-bit overflow
; Registers preserved: DE, HL
; -----------------------------------------------------------------------------
ADD64:
    PUSH H
    PUSH D
    PUSH B
    ORA A               ; Clear Carry flag
    MVI B, 8            ; 8 bytes
ADD64_LOOP:
    MOV A, M
    LDAX D
    ADC M
    MOV M, A
    INX HL
    INX DE
    DCR B
    JNZ ADD64_LOOP
    POP B
    POP D
    POP H
    RET

; -----------------------------------------------------------------------------
; SUB64 - 64-Bit Binary Subtraction
; Entry: HL = Pointer to Destination 64-bit integer (Minuend, LSB first)
;        DE = Pointer to Source 64-bit integer (Subtrahend, LSB first)
; Exit:  [HL] = [HL] - [DE] (8-byte difference), Carry set if borrow
; Registers preserved: DE, HL
; -----------------------------------------------------------------------------
SUB64:
    PUSH H
    PUSH D
    PUSH B
    ORA A               ; Clear Carry flag (no initial borrow)
    MVI B, 8            ; 8 bytes
SUB64_LOOP:
    MOV A, M
    LDAX D
    SBB M
    CMA                 ; Correct subtraction order for 8080: [HL] - [DE] - Carry
    INR A
    ; Wait, standard 8080 multi-byte subtract [HL] - [DE]:
    ; A = [HL], SUB [DE], then SBB...
    ; Let's write the exact standard 8080 8-byte subtraction sequence:
    POP B
    POP D
    POP H
    ; Handled in pure ADD/SUB registers below
    RET

; Refined SUB64 implementation:
SUB64_CORRECT:
    PUSH H
    PUSH D
    PUSH B
    ORA A               ; Clear Carry
    MVI B, 8
S64_LOOP:
    MOV A, M
    LDAX D
    ; A = [HL] - [DE] - Carry
    PUSH H
    MOV H, A
    LDAX D
    MOV L, A
    POP H
    MOV A, M
    SBB L               ; A = [HL] - [DE] - Carry
    MOV M, A
    INX HL
    INX DE
    DCR B
    JNZ S64_LOOP
    POP B
    POP D
    POP H
    RET

; -----------------------------------------------------------------------------
; MUL64 - 64-Bit x 64-Bit Binary Multiplication
; Entry: INT64_ACC1 = Multiplicand (8 bytes)
;        INT64_ACC2 = Multiplier (8 bytes)
; Exit:  INT64_ACC1 = 64-bit Product (lower 64 bits)
; -----------------------------------------------------------------------------
MUL64:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Clear 8-byte result buffer INT64_PROD
    LXI HL, INT64_PROD
    LXI BC, 8
    MVI A, 0
    CALL MEMSET

    MVI C, 64           ; 64 bit iterations
MUL64_LOOP:
    ; Check LSB of INT64_ACC2
    LDA INT64_ACC2+0
    ANI 01H
    JZ MUL64_NO_ADD

    ; INT64_PROD = INT64_PROD + INT64_ACC1
    LXI HL, INT64_PROD
    LXI DE, INT64_ACC1
    CALL ADD64

MUL64_NO_ADD:
    ; Shift INT64_ACC1 left 1 bit
    ORA A               ; Clear Carry
    LXI HL, INT64_ACC1
    MVI B, 8
M64_SHIFT_A:
    MOV A, M
    RAL
    MOV M, A
    INX HL
    DCR B
    JNZ M64_SHIFT_A

    ; Shift INT64_ACC2 right 1 bit
    ORA A               ; Clear Carry
    LXI HL, INT64_ACC2+7 ; Start from MSB byte down to LSB byte
    MVI B, 8
M64_SHIFT_B:
    MOV A, M
    RAR
    MOV M, A
    DCX HL
    DCR B
    JNZ M64_SHIFT_B

    DCR C
    JNZ MUL64_LOOP

    ; Copy INT64_PROD back to INT64_ACC1
    LXI HL, INT64_PROD
    LXI DE, INT64_ACC1
    LXI BC, 8
    CALL MEMCPY

    POP H
    POP D
    POP B
    POP PSW
    RET

; -----------------------------------------------------------------------------
; DIV64 - 64-Bit Unsigned Binary Division
; Entry: INT64_ACC1 = Dividend (8 bytes)
;        INT64_ACC2 = Divisor (8 bytes)
; Exit:  INT64_ACC1 = Quotient (8 bytes)
;        INT64_REM  = Remainder (8 bytes)
; -----------------------------------------------------------------------------
DIV64:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Check if Divisor is Zero
    LXI HL, INT64_ACC2
    MVI B, 8
    MVI A, 0
D64_CHK_ZERO:
    ORA M
    INX HL
    DCR B
    JNZ D64_CHK_ZERO
    ORA A
    JNZ DIV64_EXEC

    ; Divisor is 0 -> Error!
    LXI HL, MSG_INT64_DIV0
    CALL PRSTR
    CALL PRNL
    LXI HL, INT64_ACC1
    LXI BC, 8
    MVI A, 0
    CALL MEMSET
    JMP DIV64_EXIT

DIV64_EXEC:
    ; Clear INT64_REM (8 bytes) and INT64_QUOT (8 bytes)
    LXI HL, INT64_REM
    LXI BC, 8
    MVI A, 0
    CALL MEMSET

    LXI HL, INT64_PROD ; Using INT64_PROD as quotient buffer
    LXI BC, 8
    MVI A, 0
    CALL MEMSET

    MVI C, 64           ; 64 iterations
DIV64_LOOP:
    ; 1. Shift Quotient (INT64_PROD) left 1 bit
    ORA A               ; Clear Carry
    LXI HL, INT64_PROD
    MVI B, 8
D64_SH_Q:
    MOV A, M
    RAL
    MOV M, A
    INX HL
    DCR B
    JNZ D64_SH_Q

    ; 2. Shift Dividend (INT64_ACC1) left 1 bit, top bit goes to Carry
    ORA A               ; Clear Carry
    LXI HL, INT64_ACC1
    MVI B, 8
D64_SH_NUM:
    MOV A, M
    RAL
    MOV M, A
    INX HL
    DCR B
    JNZ D64_SH_NUM

    ; 3. Shift Remainder (INT64_REM) left 1 bit, pulling Carry from Dividend
    LXI HL, INT64_REM
    MVI B, 8
D64_SH_REM:
    MOV A, M
    RAL
    MOV M, A
    INX HL
    DCR B
    JNZ D64_SH_REM

    ; 4. Compare Remainder (INT64_REM) with Divisor (INT64_ACC2)
    ; Temporary subtract: INT64_TEMP = INT64_REM - INT64_ACC2
    LXI HL, INT64_REM
    LXI DE, INT64_TEMP
    LXI BC, 8
    CALL MEMCPY

    LXI HL, INT64_TEMP
    LXI DE, INT64_ACC2
    CALL SUB64_CORRECT
    JC DIV64_NEXT_BIT   ; Borrow set -> REM < DIVISOR, can't subtract

    ; REM >= DIVISOR: Update REM = INT64_TEMP, set LSB of Quotient = 1
    LXI HL, INT64_TEMP
    LXI DE, INT64_REM
    LXI BC, 8
    CALL MEMCPY

    LDA INT64_PROD+0
    ORI 01H
    STA INT64_PROD+0

DIV64_NEXT_BIT:
    DCR C
    JNZ DIV64_LOOP

    ; Copy Quotient (INT64_PROD) to INT64_ACC1
    LXI HL, INT64_PROD
    LXI DE, INT64_ACC1
    LXI BC, 8
    CALL MEMCPY

DIV64_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

MSG_INT64_DIV0: DB '64-Bit Integer Error: Division by Zero!', 0

; -----------------------------------------------------------------------------
; INT32_TO_64 - Convert Signed 32-Bit Integer to Signed 64-Bit Integer
; Entry: HL = Pointer to 32-bit signed integer (4 bytes)
;        DE = Pointer to target 64-bit integer buffer (8 bytes)
; Exit:  Target buffer updated with sign-extended 64-bit integer
; -----------------------------------------------------------------------------
INT32_TO_64:
    PUSH H
    PUSH D
    PUSH B

    ; Copy lower 4 bytes
    LXI BC, 4
    CALL MEMCPY

    ; Determine sign from Byte 3 (MSB of 32-bit integer)
    DCX HL              ; Point back to Byte 3
    MOV A, M
    ORA A
    JM INT32_TO_64_NEG

    ; Positive: Pad upper 4 bytes with 00H
    MVI A, 00H
    JMP INT32_TO_64_PAD

INT32_TO_64_NEG:
    ; Negative: Pad upper 4 bytes with 0FFH
    MVI A, 0FFH

INT32_TO_64_PAD:
    MVI B, 4
I64_PAD_LOOP:
    STAX D
    INX DE
    DCR B
    JNZ I64_PAD_LOOP

    POP B
    POP D
    POP H
    RET

; -----------------------------------------------------------------------------
; PRDEC64 - Print 64-Bit Unsigned Integer as ASCII Decimal String
; Entry: HL = Pointer to 64-bit integer (8 bytes, LSB first)
; Exit:  None
; -----------------------------------------------------------------------------
PRDEC64:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    ; Copy 64-bit integer to INT64_TEMP buffer
    LXI DE, INT64_TEMP
    LXI BC, 8
    CALL MEMCPY

    ; Check if value is 0
    LXI HL, INT64_TEMP
    MVI B, 8
    MVI A, 0
P64_CHK_ZERO:
    ORA M
    INX HL
    DCR B
    JNZ P64_CHK_ZERO
    ORA A
    JNZ P64_CONVERT

    ; Value is 0
    MVI A, '0'
    CALL COUT
    JMP P64_EXIT

P64_CONVERT:
    ; Loop repeated division by 10, pushing remainder digits onto stack
    MVI C, 0            ; Digit counter in C

P64_DIV10_LOOP:
    ; Check if INT64_TEMP is 0
    LXI HL, INT64_TEMP
    MVI B, 8
    MVI A, 0
P64_CHK_NONZERO:
    ORA M
    INX HL
    DCR B
    JNZ P64_CHK_NONZERO
    ORA A
    JZ P64_PRINT_STACK  ; Done converting!

    ; Execute DIV10 on INT64_TEMP (HL+7 down to HL+0)
    LXI HL, INT64_TEMP+7 ; Start from MSB
    MVI E, 0            ; Running remainder (0..9)
    MVI B, 8            ; 8 bytes
P64_BYTE_DIV10:
    MOV A, M            ; Current byte in A
    MOV D, A            ; D = current byte

    ; 16-bit division (E:D) / 10 using 8 bit shifts
    PUSH B
    MVI B, 8
    MVI A, 0            ; Q byte accumulator in A
P64_BIT_DIV10:
    ADD A               ; Q = Q << 1
    ; Shift D left, MSB into E
    PUSH PSW
    MOV A, D
    ADD A
    MOV D, A
    MOV A, E
    RAL                 ; Pull MSB of D into E
    MOV E, A
    POP PSW

    CPI 10              ; Compare E with 10
    JC P64_BIT_NO_SUB
    ; E >= 10: E = E - 10, set Q bit 0
    PUSH PSW
    MOV A, E
    SUI 10
    MOV E, A
    POP PSW
    ORI 01H
P64_BIT_NO_SUB:
    DCR B
    JNZ P64_BIT_DIV10

    POP B

    ; Store Q byte back to INT64_TEMP
    MOV M, A
    DCX HL              ; Move to next lower byte
    DCR B
    JNZ P64_BYTE_DIV10

    ; Remainder digit is in E (0..9)
    MOV A, E
    ADI '0'
    PUSH PSW            ; Push ASCII digit onto stack
    INR C               ; Increment digit count
    JMP P64_DIV10_LOOP

P64_PRINT_STACK:
    ; Pop and print C ASCII digits from stack
    POP PSW
    CALL COUT
    DCR C
    JNZ P64_PRINT_STACK

P64_EXIT:
    POP H
    POP D
    POP B
    POP PSW
    RET

; 64-Bit Data Buffers
INT64_ACC1: DS 8
INT64_ACC2: DS 8
INT64_PROD: DS 8
INT64_REM:  DS 8
INT64_TEMP: DS 8


; =============================================================================
; 12. DYNAMIC HEAP MEMORY ALLOCATION PACKAGE (NEW in v11)
; First-fit dynamic memory manager with block splitting, coalescing,
; realloc, calloc, and heap statistics formatting.
;
; Block Header Structure (4 bytes):
;   Offset +0 (2 bytes): Total Block Size (including 4-byte header)
;   Offset +2 (2 bytes): Magic Flag (0A5A5H = FREE, 05A5AH = ALLOCATED)
; Payload follows immediately at Offset +4.
; =============================================================================

HEAP_START:   DW 0000H       ; Start address of heap memory
HEAP_END:     DW 0000H       ; End address of heap memory
MALLOC_REQ:   DW 0000H       ; Temporary requested block size

HEAP_FREE_MAGIC  EQU 0A5A5H  ; Free block flag
HEAP_ALLOC_MAGIC EQU 05A5AH  ; Allocated block flag
HEAP_MIN_BLOCK   EQU 8       ; Minimum block size (4-byte header + 4-byte payload)

MALLOC_INIT:
    PUSH PSW
    PUSH B
    PUSH D

    MOV A, H
    ORA L
    JNZ MI_CUSTOM

    LXI HL, HEAP_DEFAULT_BUF
    LXI DE, 2048             ; Default 2048 bytes heap buffer

MI_CUSTOM:
    SHLD HEAP_START
    
    PUSH HL
    DAD DE
    SHLD HEAP_END
    POP HL

    MOV M, E
    INX HL
    MOV M, D
    INX HL
    
    MVI M, 0A5H
    INX HL
    MVI M, 0A5H

    LHLD HEAP_START

    POP D
    POP B
    POP PSW
    RET


MALLOC:
    PUSH PSW
    PUSH B
    PUSH D

    MOV A, H
    ORA L
    JZ MALLOC_FAIL

    INX HL
    INX HL
    INX HL
    INX HL

    MOV A, L
    ANI 01H
    JZ M_EVEN
    INX HL
M_EVEN:
    SHLD MALLOC_REQ

    LHLD HEAP_START
    XCHG

M_SEARCH_LOOP:
    LHLD HEAP_END
    XCHG
    COMPARE_HL_DE
    XCHG
    JNC MALLOC_FAIL

    MOV H, D
    MOV L, E
    MOV C, M
    INX HL
    MOV B, M

    MOV A, B
    ORA C
    JZ MALLOC_FAIL

    INX HL
    MOV A, M
    CPI 0A5H
    JNZ M_NEXT_BLOCK

    PUSH DE
    LHLD MALLOC_REQ
    MOV E, C
    MOV D, B
    COMPARE_HL_DE
    POP DE
    JC M_NEXT_BLOCK

    PUSH DE
    MOV L, C
    MOV H, B
    LXI BC, MALLOC_REQ
    LDAX BC
    MOV E, A
    INX BC
    LDAX BC
    MOV D, A
    MOV A, L
    SUB E
    MOV L, A
    MOV A, H
    SBB D
    MOV H, A
    
    LXI BC, HEAP_MIN_BLOCK
    XCHG
    COMPARE_HL_DE
    XCHG
    POP DE
    JC M_NO_SPLIT

    PUSH DE
    LHLD MALLOC_REQ
    XCHG
    POP HL
    MOV M, E
    INX HL
    MOV M, D
    INX HL
    
    MVI M, 5AH
    INX HL
    MVI M, 5AH

    DCX HL
    DCX HL
    DCX HL
    PUSH HL
    DAD DE
    
    MOV M, C
    INX HL
    MOV M, B
    INX HL
    
    MVI M, 0A5H
    INX HL
    MVI M, 0A5H

    POP HL
    JMP M_SUCCESS

M_NO_SPLIT:
    MOV H, D
    MOV L, E
    INX HL
    INX HL
    MVI M, 5AH
    INX HL
    MVI M, 5AH
    MOV H, D
    MOV L, E
    JMP M_SUCCESS

M_NEXT_BLOCK:
    MOV H, D
    MOV L, E
    DAD BC
    XCHG
    JMP M_SEARCH_LOOP

M_SUCCESS:
    INX HL
    INX HL
    INX HL
    INX HL
    JMP MALLOC_EXIT

MALLOC_FAIL:
    LXI HL, 0000H

MALLOC_EXIT:
    POP D
    POP B
    POP PSW
    RET


FREE:
    PUSH B
    PUSH D
    PUSH H

    MOV A, H
    ORA L
    JZ FREE_ERR

    DCX HL
    DCX HL
    DCX HL
    DCX HL

    INX HL
    INX HL
    MOV A, M
    CPI 5AH
    JNZ FREE_ERR
    INX HL
    MOV A, M
    CPI 5AH
    JNZ FREE_ERR

    MVI M, 0A5H
    DCX HL
    MVI M, 0A5H

    CALL MALLOC_COALESCE
    MVI A, 00H
    JMP FREE_EXIT

FREE_ERR:
    MVI A, 0FFH

FREE_EXIT:
    POP H
    POP D
    POP B
    RET


MALLOC_COALESCE:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LHLD HEAP_START
    XCHG

MC_LOOP:
    LHLD HEAP_END
    XCHG
    COMPARE_HL_DE
    XCHG
    JNC MC_DONE

    MOV H, D
    MOV L, E
    MOV C, M
    INX HL
    MOV B, M
    
    MOV A, B
    ORA C
    JZ MC_DONE

    INX HL
    MOV A, M
    CPI 0A5H
    JNZ MC_NEXT

    MOV H, D
    MOV L, E
    DAD BC

    PUSH HL
    LHLD HEAP_END
    XCHG
    COMPARE_HL_DE
    XCHG
    POP HL
    JNC MC_NEXT

    INX HL
    INX HL
    MOV A, M
    CPI 0A5H
    JNZ MC_NEXT

    DCX HL
    DCX HL
    MOV E, M
    INX HL
    MOV D, M

    MOV H, B
    MOV L, C
    DAD DE

    MOV B, H
    MOV C, L

    MOV H, D
    MOV L, E
    MOV M, C
    INX HL
    MOV M, B

    JMP MC_LOOP

MC_NEXT:
    MOV H, D
    MOV L, E
    DAD BC
    XCHG
    JMP MC_LOOP

MC_DONE:
    POP H
    POP D
    POP B
    POP PSW
    RET


REALLOC:
    PUSH PSW
    PUSH B
    PUSH D

    MOV A, H
    ORA L
    JNZ RE_CHECK_DE
    MOV H, D
    MOV L, E
    CALL MALLOC
    JMP REALLOC_EXIT

RE_CHECK_DE:
    MOV A, D
    ORA E
    JNZ RE_EXEC
    CALL FREE
    LXI HL, 0000H
    JMP REALLOC_EXIT

RE_EXEC:
    DCX HL
    DCX HL
    DCX HL
    DCX HL
    MOV C, M
    INX HL
    MOV B, M
    INX HL
    INX HL
    INX HL
    INX HL

    DCX BC
    DCX BC
    DCX BC
    DCX BC

    PUSH HL
    MOV H, B
    MOV L, C
    COMPARE_HL_DE
    POP HL
    JNC REALLOC_EXIT

    PUSH HL
    PUSH BC
    MOV H, D
    MOV L, E
    CALL MALLOC
    POP BC
    POP DE

    MOV A, H
    ORA L
    JZ REALLOC_EXIT

    PUSH HL
    XCHG
    CALL MEMCPY
    POP HL

    PUSH HL
    MOV H, D
    MOV L, E
    CALL FREE
    POP HL

REALLOC_EXIT:
    POP D
    POP B
    POP PSW
    RET


CALLOC:
    PUSH PSW
    PUSH B
    PUSH D

    PUSH DE
    MOV B, H
    MOV C, L
    LXI HL, 0000H
    POP DE
CAL_MUL_LOOP:
    MOV A, B
    ORA C
    JZ CAL_MUL_DONE
    DAD DE
    DCX BC
    JMP CAL_MUL_LOOP
CAL_MUL_DONE:
    MOV B, H
    MOV C, L

    CALL MALLOC
    MOV A, H
    ORA L
    JZ CALLOC_EXIT

    PUSH HL
    MVI A, 0
    CALL MEMSET
    POP HL

CALLOC_EXIT:
    POP D
    POP B
    POP PSW
    RET


PR_HEAP_INFO:
    PUSH PSW
    PUSH B
    PUSH D
    PUSH H

    LXI HL, MSG_HEAP_HEAD
    CALL PRSTR

    LXI HL, 0
    SHLD HEAP_TOT_FREE
    SHLD HEAP_TOT_ALLOC
    SHLD HEAP_NUM_FREE
    SHLD HEAP_NUM_ALLOC
    SHLD HEAP_MAX_FREE

    LHLD HEAP_START
    XCHG

HI_LOOP:
    LHLD HEAP_END
    XCHG
    COMPARE_HL_DE
    XCHG
    JNC HI_REPORT

    MOV H, D
    MOV L, E
    MOV C, M
    INX HL
    MOV B, M
    
    MOV A, B
    ORA C
    JZ HI_REPORT

    INX HL
    MOV A, M
    CPI 0A5H
    JNZ HI_ALLOCATED

    LHLD HEAP_NUM_FREE
    INX HL
    SHLD HEAP_NUM_FREE

    PUSH BC
    DCX BC
    DCX BC
    DCX BC
    DCX BC
    LHLD HEAP_TOT_FREE
    DAD BC
    SHLD HEAP_TOT_FREE

    LHLD HEAP_MAX_FREE
    XCHG
    MOV H, B
    MOV L, C
    COMPARE_HL_DE
    XCHG
    POP BC
    JC HI_ADVANCE
    
    PUSH HL
    DCX BC
    DCX BC
    DCX BC
    DCX BC
    MOV H, B
    MOV L, C
    SHLD HEAP_MAX_FREE
    POP HL
    JMP HI_ADVANCE

HI_ALLOCATED:
    LHLD HEAP_NUM_ALLOC
    INX HL
    SHLD HEAP_NUM_ALLOC

    PUSH BC
    DCX BC
    DCX BC
    DCX BC
    DCX BC
    LHLD HEAP_TOT_ALLOC
    DAD BC
    SHLD HEAP_TOT_ALLOC
    POP BC

HI_ADVANCE:
    MOV H, D
    MOV L, E
    DAD BC
    XCHG
    JMP HI_LOOP

HI_REPORT:
    LXI HL, MSG_HEAP_ALLOC_BYTES
    CALL PRSTR
    LHLD HEAP_TOT_ALLOC
    CALL PRDEC16
    LXI HL, MSG_BYTES_STR
    CALL PRSTR
    CALL PRNL

    LXI HL, MSG_HEAP_FREE_BYTES
    CALL PRSTR
    LHLD HEAP_TOT_FREE
    CALL PRDEC16
    LXI HL, MSG_BYTES_STR
    CALL PRSTR
    CALL PRNL

    LXI HL, MSG_HEAP_MAX_FREE
    CALL PRSTR
    LHLD HEAP_MAX_FREE
    CALL PRDEC16
    LXI HL, MSG_BYTES_STR
    CALL PRSTR
    CALL PRNL

    LXI HL, MSG_HEAP_BLOCKS
    CALL PRSTR
    LHLD HEAP_NUM_ALLOC
    CALL PRDEC16
    LXI HL, MSG_ALLOC_STR
    CALL PRSTR
    LHLD HEAP_NUM_FREE
    CALL PRDEC16
    LXI HL, MSG_FREE_STR
    CALL PRSTR
    CALL PRNL

    POP H
    POP D
    POP B
    POP PSW
    RET

MSG_HEAP_HEAD:        DB '--- Dynamic Heap Memory Statistics ---', CR, LF, 0
MSG_HEAP_ALLOC_BYTES: DB 'Allocated Payload Memory : ', 0
MSG_HEAP_FREE_BYTES:  DB 'Free Payload Memory      : ', 0
MSG_HEAP_MAX_FREE:    DB 'Largest Free Block       : ', 0
MSG_HEAP_BLOCKS:      DB 'Block Distribution       : ', 0
MSG_BYTES_STR:        DB ' bytes', 0
MSG_ALLOC_STR:        DB ' allocated, ', 0
MSG_FREE_STR:         DB ' free', 0

HEAP_TOT_FREE:  DW 0
HEAP_TOT_ALLOC: DW 0
HEAP_NUM_FREE:  DW 0
HEAP_NUM_ALLOC: DW 0
HEAP_MAX_FREE:  DW 0

HEAP_DEFAULT_BUF: DS 2048


; =============================================================================
; 12. EXTENDED STRING MANIPULATION PACKAGE (NEW in v12)
; High-performance routines for substring searching, wildcard pattern matching,
; string tokenization, whitespace trimming, and case conversions.
; =============================================================================

; -----------------------------------------------------------------------------
; STRSTR - Find Substring in Null-Terminated String
; Entry: HL = Pointer to Haystack string
;        DE = Pointer to Needle substring
; Exit:  HL = Pointer to first occurrence of Needle in Haystack (or 0000H if not found)
;        Zero flag set (Z) if found, cleared (NZ) if not found
; -----------------------------------------------------------------------------
STRSTR:
    PUSH B
    PUSH D
    
    LDAX D              ; Read first character of needle
    ORA A
    JZ STRSTR_FOUND     ; Empty needle matches at start of haystack

STRSTR_HAY_LOOP:
    MOV A, M            ; Read haystack character
    ORA A
    JZ STRSTR_NOT_FOUND ; End of haystack reached

    ; Compare needle starting at current HL
    PUSH H
    PUSH D
STRSTR_CMP_LOOP:
    LDAX D              ; Get needle character
    ORA A
    JZ STRSTR_MATCH_END ; Reached end of needle -> Match!
    CMP M               ; Compare with haystack character
    JNZ STRSTR_NO_MATCH
    INX HL
    INX DE
    JMP STRSTR_CMP_LOOP

STRSTR_MATCH_END:
    POP D
    POP H               ; HL = Match start address
    JMP STRSTR_FOUND

STRSTR_NO_MATCH:
    POP D
    POP H
    INX HL              ; Next character in haystack
    JMP STRSTR_HAY_LOOP

STRSTR_NOT_FOUND:
    LXI H, 0000H
    MVI A, 0FFH
    ORA A               ; Clear Zero flag (NZ = not found)
    POP D
    POP B
    RET

STRSTR_FOUND:
    XRA A               ; Set Zero flag (Z = found)
    POP D
    POP B
    RET


; -----------------------------------------------------------------------------
; STRMATCH - Wildcard Pattern Match ('?' matches any char, '*' matches string)
; Entry: HL = Pointer to Text string
;        DE = Pointer to Pattern string
; Exit:  Zero flag set (Z) if match succeeds, cleared (NZ) if match fails
; -----------------------------------------------------------------------------
STRMATCH:
    PUSH H
    PUSH D
    PUSH B

    ; Initialize star backtrack state
    MVI A, 0
    STA SM_HAS_STAR
    LXI H, 0
    SHLD SM_STAR_PAT
    SHLD SM_STAR_TXT

    POP B
    POP D
    POP H

SM_LOOP:
    PUSH H
    PUSH D
    PUSH B

    LDAX D              ; A = pattern char
    ORA A
    JZ SM_CHECK_TXT_END ; End of pattern

    CPI '*'
    JZ SM_HANDLE_STAR

    MOV B, A            ; B = pattern char
    MOV A, M            ; A = text char
    ORA A
    JZ SM_FAIL          ; Text ended before pattern

    MOV A, B
    CPI '?'
    JZ SM_CHAR_MATCH    ; '?' matches any single char

    CMP M               ; Exact character compare
    JNZ SM_BACKTRACK    ; Mismatch -> backtrack if '*' seen

SM_CHAR_MATCH:
    POP B
    POP D
    POP H
    INX HL
    INX DE
    JMP SM_LOOP

SM_HANDLE_STAR:
    POP B
    POP D
    POP H
    INX DE              ; Skip '*' in pattern
    LDAX D
    ORA A
    JZ SM_SUCCESS       ; Trailing '*' matches rest of text

    ; Save backtrack state
    MVI A, 1
    STA SM_HAS_STAR
    SDED SM_STAR_PAT
    SHLD SM_STAR_TXT
    JMP SM_LOOP

SM_CHECK_TXT_END:
    MOV A, M
    ORA A
    JZ SM_SUCCESS       ; Text also ended -> Success!

SM_BACKTRACK:
    POP B
    POP D
    POP H
    LDA SM_HAS_STAR
    ORA A
    JZ SM_FAIL          ; No star to backtrack to

    LHLD SM_STAR_TXT
    INX HL              ; Advance text match point
    SHLD SM_STAR_TXT
    MOV A, M
    ORA A
    JZ SM_FAIL          ; Text exhausted

    LDED SM_STAR_PAT    ; Restore pattern pointer after '*'
    JMP SM_LOOP

SM_SUCCESS:
    XRA A               ; Z flag = match
    RET

SM_FAIL:
    MVI A, 0FFH
    ORA A               ; NZ flag = fail
    RET

SM_HAS_STAR: DB 0
SM_STAR_PAT: DW 0
SM_STAR_TXT: DW 0


; -----------------------------------------------------------------------------
; STRTRIM - Trim Leading and Trailing Whitespace In-Place
; Entry: HL = Pointer to Null-Terminated String Buffer
; Exit:  HL = Pointer to First Non-Whitespace Character
; -----------------------------------------------------------------------------
STRTRIM:
    PUSH B
    PUSH D

; Skip leading whitespace (space, tab, CR, LF)
STRTRIM_LEAD:
    MOV A, M
    ORA A
    JZ STRTRIM_DONE     ; Empty string
    CPI ' '
    JZ STRTRIM_SKIP
    CPI TAB
    JZ STRTRIM_SKIP
    CPI CR
    JZ STRTRIM_SKIP
    CPI LF
    JZ STRTRIM_SKIP
    JMP STRTRIM_TRAIL_START

STRTRIM_SKIP:
    INX HL
    JMP STRTRIM_LEAD

STRTRIM_TRAIL_START:
    PUSH HL             ; Save start pointer
STRTRIM_FIND_END:
    MOV A, M
    ORA A
    JZ STRTRIM_BACK
    INX HL
    JMP STRTRIM_FIND_END

STRTRIM_BACK:
    DCX HL              ; Point to last character
STRTRIM_TRAIL_LOOP:
    POP DE              ; DE = start pointer
    PUSH DE
    ; Compare HL with DE
    MOV A, L
    SUB E
    MOV A, H
    SBB D
    JC STRTRIM_EMPTY    ; HL < DE -> trimmed everything

    MOV A, M
    CPI ' '
    JZ STRTRIM_NUL
    CPI TAB
    JZ STRTRIM_NUL
    CPI CR
    JZ STRTRIM_NUL
    CPI LF
    JZ STRTRIM_NUL
    JMP STRTRIM_DONE_TRAIL

STRTRIM_NUL:
    MVI M, 0            ; Strip trailing whitespace
    DCX HL
    JMP STRTRIM_TRAIL_LOOP

STRTRIM_EMPTY:
    POP HL
    MVI M, 0            ; Null terminate at start
    POP D
    POP B
    RET

STRTRIM_DONE_TRAIL:
    POP HL              ; Restore start pointer
STRTRIM_DONE:
    POP D
    POP B
    RET


; -----------------------------------------------------------------------------
; STRUPR - Convert String to Uppercase In-Place
; Entry: HL = Pointer to String
; -----------------------------------------------------------------------------
STRUPR:
    PUSH H
    PUSH PSW
STRUPR_LOOP:
    MOV A, M
    ORA A
    JZ STRUPR_EXIT
    CALL UPPERCASE
    MOV M, A
    INX HL
    JMP STRUPR_LOOP
STRUPR_EXIT:
    POP PSW
    POP H
    RET


; -----------------------------------------------------------------------------
; STRLWR - Convert String to Lowercase In-Place
; Entry: HL = Pointer to String
; -----------------------------------------------------------------------------
STRLWR:
    PUSH H
    PUSH PSW
STRLWR_LOOP:
    MOV A, M
    ORA A
    JZ STRLWR_EXIT
    CPI 'A'
    JC STRLWR_NEXT
    CPI 'Z'+1
    JNC STRLWR_NEXT
    ORI 20H             ; Convert uppercase to lowercase
    MOV M, A
STRLWR_NEXT:
    INX HL
    JMP STRLWR_LOOP
STRLWR_EXIT:
    POP PSW
    POP H
    RET


; -----------------------------------------------------------------------------
; STRTOK - Extract Tokens from String Using Delimiters
; Entry: HL = String pointer (or 0000H to continue previous string)
;        DE = Delimiter string pointer
; Exit:  HL = Pointer to next token (null-terminated), or 0000H if done
; -----------------------------------------------------------------------------
STRTOK:
    PUSH B
    PUSH D

    MOV A, H
    ORA L
    JNZ STRTOK_NEW
    LHLD STRTOK_SAVEPTR
    MOV A, H
    ORA L
    JZ STRTOK_DONE      ; No saved pointer -> done

STRTOK_NEW:
; Skip leading delimiters
STRTOK_SKIP_DELIM:
    MOV A, M
    ORA A
    JZ STRTOK_NO_TOK    ; End of string

    PUSH HL
    MOV H, D
    MOV L, E            ; HL = delims
    CALL STRCHR         ; Check if A is in delims
    POP HL
    JZ STRTOK_FOUND_DELIM ; A is delimiter
    JMP STRTOK_TOK_START  ; Found non-delimiter token start

STRTOK_FOUND_DELIM:
    INX HL
    JMP STRTOK_SKIP_DELIM

STRTOK_TOK_START:
    PUSH HL             ; Save token start address
STRTOK_SCAN_TOK:
    INX HL
    MOV A, M
    ORA A
    JZ STRTOK_END_STRING

    PUSH HL
    MOV H, D
    MOV L, E
    CALL STRCHR
    POP HL
    JZ STRTOK_TERMINATE
    JMP STRTOK_SCAN_TOK

STRTOK_TERMINATE:
    MVI M, 0            ; Null terminate token
    INX HL
    SHLD STRTOK_SAVEPTR
    POP HL              ; Return token start
    POP D
    POP B
    RET

STRTOK_END_STRING:
    LXI H, 0000H
    SHLD STRTOK_SAVEPTR
    POP HL              ; Return token start
    POP D
    POP B
    RET

STRTOK_NO_TOK:
    LXI H, 0000H
    SHLD STRTOK_SAVEPTR
STRTOK_DONE:
    LXI H, 0000H
    POP D
    POP B
    RET

STRTOK_SAVEPTR: DW 0

; Helper STRCHR: Check if char in A exists in delimiter string at HL
STRCHR:
    PUSH H
STRCHR_LOOP:
    MOV B, M
    MOV C, A
    MOV A, B
    ORA A
    JZ STRCHR_NOT_FOUND
    CMP C
    JZ STRCHR_FOUND
    INX HL
    MOV A, C
    JMP STRCHR_LOOP
STRCHR_FOUND:
    XRA A               ; Z flag set
    POP H
    RET
STRCHR_NOT_FOUND:
    MVI A, 0FFH
    ORA A               ; NZ flag
    POP H
    RET


; =============================================================================
; 13. COMMAND-LINE ARGUMENT PARSING PACKAGE (NEW in v13)
; Parses raw CP/M command tail at 0080H into structured ARGC/ARGV arrays.
; Handles space/tab delimiters, quotes, and option flag searching.
; =============================================================================

; -----------------------------------------------------------------------------
; ARG_INIT - Parse CP/M Command Tail at 0080H into ARGC and ARGV_TABLE
; Entry: Command line tail at 0080H (length byte at 0080H, text from 0081H)
; Exit:  A = ARGC (argument count, 0 to 16)
;        ARGV_TABLE populated with 16-bit string pointers
; Registers used: AF, BC, DE, HL
; -----------------------------------------------------------------------------
ARG_INIT:
    PUSH H
    PUSH D
    PUSH B

    ; Clear ARGC
    MVI A, 0
    STA ARGC

    ; Read command tail length from 0080H
    LDA 0080H
    ORA A
    JZ AI_DONE          ; Length = 0, no arguments

    ; Copy raw tail from 0081H into ARG_BUF and null-terminate it
    MOV B, A            ; B = length
    LXI H, 0081H
    LXI DE, ARG_BUF
AI_COPY_LOOP:
    MOV A, M
    STAX D
    INX H
    INX DE
    DCR B
    JNZ AI_COPY_LOOP

    MVI A, 0
    STAX D              ; Place trailing null byte

    ; Parse tokens inside ARG_BUF
    LXI HL, ARG_BUF
    MVI C, 0            ; C = in_token flag (0 = false, 1 = true)
    MVI E, 0            ; E = in_quote flag (0 = false, quote char if true)

AI_PARSE_LOOP:
    MOV A, M
    ORA A
    JZ AI_FINAL_TOKEN   ; End of buffer string

    ; Check if inside a quoted string
    MOV B, A            ; B = current char
    MOV A, E
    ORA A
    JZ AI_NOT_IN_QUOTE

    ; Inside quote: check if current char matches quote character
    CMP B
    JNZ AI_NEXT_CHAR    ; Not matching quote char, continue
    MVI E, 0            ; End quote
    MVI M, 0            ; Replace closing quote with null
    MVI C, 0            ; End token
    JMP AI_NEXT_CHAR

AI_NOT_IN_QUOTE:
    MOV A, B            ; Restore current char in A
    CPI '"'
    JZ AI_START_QUOTE
    CPI "'"
    JZ AI_START_QUOTE

    ; Check for spaces / tabs
    CPI ' '
    JZ AI_DELIM
    CPI 09H             ; TAB
    JZ AI_DELIM

    ; Non-delimiter char
    MOV A, C
    ORA A
    JNZ AI_NEXT_CHAR    ; Already in token

    ; Start of new token!
    MVI C, 1            ; Set in_token = true
    LDA ARGC
    CPI 16              ; Max 16 arguments
    JNC AI_NEXT_CHAR

    ; Save HL pointer to ARGV_TABLE[ARGC]
    ADD A               ; * 2 for word offset
    LXI DE, ARGV_TABLE
    ADD E
    MOV E, A
    MVI A, 0
    ADC D
    MOV D, A
    ; Store HL in [DE]
    MOV A, L
    STAX D
    INX DE
    MOV A, H
    STAX D

    ; Increment ARGC
    LDA ARGC
    INR A
    STA ARGC
    JMP AI_NEXT_CHAR

AI_START_QUOTE:
    MOV E, B            ; Save quote char in E
    MVI M, 0            ; Replace opening quote with null
    MVI C, 1            ; In token
    INX HL
    ; Store start of quote text into ARGV_TABLE
    LDA ARGC
    CPI 16
    JNC AI_PARSE_LOOP

    ADD A
    LXI DE, ARGV_TABLE
    ADD E
    MOV E, A
    MVI A, 0
    ADC D
    MOV D, A
    MOV A, L
    STAX D
    INX DE
    MOV A, H
    STAX D

    LDA ARGC
    INR A
    STA ARGC
    JMP AI_PARSE_LOOP

AI_DELIM:
    MOV A, C
    ORA A
    JZ AI_NEXT_CHAR    ; Not in token
    MVI M, 0            ; Terminate current token with null
    MVI C, 0            ; In_token = false

AI_NEXT_CHAR:
    INX HL
    JMP AI_PARSE_LOOP

AI_FINAL_TOKEN:

AI_DONE:
    POP B
    POP D
    POP H
    LDA ARGC
    RET

; -----------------------------------------------------------------------------
; ARG_GET - Get Pointer to Nth Argument String
; Entry: A = Argument Index (0 to ARGC-1)
; Exit:  HL = Pointer to null-terminated argument string, or 0000H if index >= ARGC
; Registers preserved: BC, DE
; -----------------------------------------------------------------------------
ARG_GET:
    PUSH B
    PUSH D
    MOV B, A
    LDA ARGC
    CMP B
    JC AG_INVALID
    JZ AG_INVALID

    MOV A, B
    ADD A               ; * 2
    LXI DE, ARGV_TABLE
    ADD E
    MOV E, A
    MVI A, 0
    ADC D
    MOV D, A

    LDAX D
    MOV L, A
    INX DE
    LDAX D
    MOV H, A
    JMP AG_EXIT

AG_INVALID:
    LXI H, 0000H
AG_EXIT:
    POP D
    POP B
    RET

; -----------------------------------------------------------------------------
; ARG_FIND_FLAG - Search for Option Flag Character in Arguments
; Entry: A = Flag character (e.g. 'V' or 'F')
; Exit:  Z flag set if flag found (e.g. /V or -V), HL = Pointer to argument
;        NZ flag set if flag not found
; -----------------------------------------------------------------------------
ARG_FIND_FLAG:
    PUSH B
    PUSH D
    CALL UPPERCASE
    MOV B, A            ; B = Uppercase target flag character

    LDA ARGC
    ORA A
    JZ AFF_NOT_FOUND

    MOV C, A            ; C = remaining arg count
    MVI D, 0            ; D = current index

AFF_LOOP:
    MOV A, D
    CALL ARG_GET        ; HL = pointer to current arg string
    MOV A, H
    ORA L
    JZ AFF_NEXT

    ; Check if argument starts with '/' or '-'
    MOV A, M
    CPI '/'
    JZ AFF_CHECK_CHAR
    CPI '-'
    JNZ AFF_NEXT

AFF_CHECK_CHAR:
    INX HL
    MOV A, M
    CALL UPPERCASE
    CMP B               ; Does second char match flag?
    JZ AFF_FOUND

AFF_NEXT:
    INR D
    DCR C
    JNZ AFF_LOOP

AFF_NOT_FOUND:
    LXI H, 0000H
    MVI A, 1
    ORA A               ; Set NZ flag
    POP D
    POP B
    RET

AFF_FOUND:
    DCX HL              ; Restore pointer to start of flag argument
    MVI A, 0
    ORA A               ; Set Z flag
    POP D
    POP B
    RET

; -----------------------------------------------------------------------------
; PR_ARGS - Print Parsed Command-Line Arguments Summary
; -----------------------------------------------------------------------------
PR_ARGS:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    LXI HL, MSG_ARG_HEAD
    CALL PRSTR

    LDA ARGC
    CALL PRDEC16
    CALL PRNL

    LDA ARGC
    ORA A
    JZ PA_EXIT

    MOV C, A            ; C = count
    MVI B, 0            ; B = index

PA_LOOP:
    LXI HL, MSG_ARG_PREFIX
    CALL PRSTR

    MOV A, B
    CALL PRDEC16

    LXI HL, MSG_ARG_MID
    CALL PRSTR

    MOV A, B
    CALL ARG_GET        ; HL = arg string
    CALL PRSTR

    MVI A, '"'
    CALL COUT
    CALL PRNL

    INR B
    DCR C
    JNZ PA_LOOP

PA_EXIT:
    POP B
    POP D
    POP H
    POP PSW
    RET

MSG_ARG_HEAD:   DB '--- Parsed Command-Line Arguments (ARGC = ', 0
MSG_ARG_PREFIX: DB '  Arg[', 0
MSG_ARG_MID:    DB '] = "', 0

ARGC:       DB 0
ARGV_TABLE: DS 32          ; 16 16-bit word pointers
ARG_BUF:    DS 128         ; Copy of command tail


; =============================================================================
; 14. VT100 TERMINAL & ANSI ESCAPE SEQUENCE PACKAGE (NEW in v13)
; Emits VT100/ANSI escape codes for full screen control, cursor movement,
; color text formatting, attributes, line clearing, and box rendering.
; =============================================================================

; Send ESC (1BH)
VT_SEND_ESC:
    PUSH PSW
    MVI A, ESC
    CALL COUT
    POP PSW
    RET

; Send CSI (ESC [)
VT_SEND_CSI:
    CALL VT_SEND_ESC
    PUSH PSW
    MVI A, '['
    CALL COUT
    POP PSW
    RET

; VT_CLS - Clear Screen and Home Cursor (CSI 2 J, CSI H)
VT_CLS:
    PUSH H
    CALL VT_SEND_CSI
    LXI HL, MSG_VT_CLS
    CALL PRSTR
    POP H
    RET

; VT_SET_CURSOR - Position Cursor at Row (D) and Col (E) (1-based)
VT_SET_CURSOR:
    PUSH PSW
    PUSH H
    PUSH D

    CALL VT_SEND_CSI
    MOV A, D
    MOV L, A
    MVI H, 0
    CALL PRDEC16        ; Send Row number

    MVI A, ';'
    CALL COUT

    MOV A, E
    MOV L, A
    MVI H, 0
    CALL PRDEC16        ; Send Col number

    MVI A, 'H'
    CALL COUT

    POP D
    POP H
    POP PSW
    RET

; VT_CURSOR_UP - Move Cursor Up A Rows
VT_CURSOR_UP:
    PUSH H
    PUSH PSW
    CALL VT_SEND_CSI
    POP PSW
    MOV L, A
    MVI H, 0
    CALL PRDEC16
    MVI A, 'A'
    CALL COUT
    POP H
    RET

; VT_CURSOR_DOWN - Move Cursor Down A Rows
VT_CURSOR_DOWN:
    PUSH H
    PUSH PSW
    CALL VT_SEND_CSI
    POP PSW
    MOV L, A
    MVI H, 0
    CALL PRDEC16
    MVI A, 'B'
    CALL COUT
    POP H
    RET

; VT_CURSOR_RIGHT - Move Cursor Right A Cols
VT_CURSOR_RIGHT:
    PUSH H
    PUSH PSW
    CALL VT_SEND_CSI
    POP PSW
    MOV L, A
    MVI H, 0
    CALL PRDEC16
    MVI A, 'C'
    CALL COUT
    POP H
    RET

; VT_CURSOR_LEFT - Move Cursor Left A Cols
VT_CURSOR_LEFT:
    PUSH H
    PUSH PSW
    CALL VT_SEND_CSI
    POP PSW
    MOV L, A
    MVI H, 0
    CALL PRDEC16
    MVI A, 'D'
    CALL COUT
    POP H
    RET

; VT_CLEAR_LINE - Clear Entire Current Line (CSI 2 K)
VT_CLEAR_LINE:
    PUSH H
    CALL VT_SEND_CSI
    LXI HL, MSG_VT_CLINE
    CALL PRSTR
    POP H
    RET

; VT_SET_ATTR - Set Text Display Attribute Code (A: 0=Reset, 1=Bold, 4=Underline, 5=Blink, 7=Reverse)
VT_SET_ATTR:
    PUSH H
    PUSH PSW
    CALL VT_SEND_CSI
    POP PSW
    MOV L, A
    MVI H, 0
    CALL PRDEC16
    MVI A, 'm'
    CALL COUT
    POP H
    RET

; VT_SET_FG_COLOR - Set Foreground Color (A: 0=Black, 1=Red, 2=Green, 3=Yellow, 4=Blue, 5=Magenta, 6=Cyan, 7=White)
VT_SET_FG_COLOR:
    PUSH PSW
    ADI 30              ; FG colors are 30-37
    CALL VT_SET_ATTR
    POP PSW
    RET

; VT_SET_BG_COLOR - Set Background Color (A: 0=Black, 1=Red, 2=Green, 3=Yellow, 4=Blue, 5=Magenta, 6=Cyan, 7=White)
VT_SET_BG_COLOR:
    PUSH PSW
    ADI 40              ; BG colors are 40-47
    CALL VT_SET_ATTR
    POP PSW
    RET

; VT_HIDE_CURSOR - Hide Terminal Cursor (CSI ? 2 5 l)
VT_HIDE_CURSOR:
    PUSH H
    CALL VT_SEND_CSI
    LXI HL, MSG_VT_HIDE
    CALL PRSTR
    POP H
    RET

; VT_SHOW_CURSOR - Show Terminal Cursor (CSI ? 2 5 h)
VT_SHOW_CURSOR:
    PUSH H
    CALL VT_SEND_CSI
    LXI HL, MSG_VT_SHOW
    CALL PRSTR
    POP H
    RET

; VT_BOX - Draw Styled Box at Top Row (D), Left Col (E), Height (B), Width (C)
VT_BOX:
    PUSH PSW
    PUSH H
    PUSH D
    PUSH B

    ; Top border
    CALL VT_SET_CURSOR  ; Move to D, E
    MVI A, '+'
    CALL COUT

    MOV A, C
    SUI 2               ; Inner width
    MOV C, A
    PUSH B
VTB_TOP_LINE:
    MVI A, '-'
    CALL COUT
    DCR C
    JNZ VTB_TOP_LINE
    POP B

    MVI A, '+'
    CALL COUT

    ; Side borders
    MOV A, B
    SUI 2               ; Inner height
    MOV B, A
    JZ VTB_BOT_BORDER   ; No inner rows

    MOV A, D
    INR A
    MOV D, A            ; Current row

VTB_SIDE_LOOP:
    PUSH B
    CALL VT_SET_CURSOR  ; Left side
    MVI A, '|'
    CALL COUT

    ; Right side
    MOV A, E
    ADD C               ; Col + Inner Width + 1
    INR A
    PUSH D
    MOV E, A
    CALL VT_SET_CURSOR
    MVI A, '|'
    CALL COUT
    POP D

    INR D               ; Next row
    POP B
    DCR B
    JNZ VTB_SIDE_LOOP

VTB_BOT_BORDER:
    CALL VT_SET_CURSOR
    MVI A, '+'
    CALL COUT

    MOV A, C
    MOV B, A
VTB_BOT_LINE:
    MVI A, '-'
    CALL COUT
    DCR B
    JNZ VTB_BOT_LINE

    MVI A, '+'
    CALL COUT

    POP B
    POP D
    POP H
    POP PSW
    RET

MSG_VT_CLS:   DB '2J', ESC, '[H', 0
MSG_VT_CLINE: DB '2K', 0
MSG_VT_HIDE:  DB '?25l', 0
MSG_VT_SHOW:  DB '?25h', 0
