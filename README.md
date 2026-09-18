# 8080 / Z80 CP/M 2.2 Assembly Function & Structured Control Library

A comprehensive, high-performance assembly function library and structured control-flow macro package for the **Intel 8080, Intel 8085, and Zilog Z80** microprocessors running Digital Research's **CP/M 2.2** operating system [cite: 3, 110, 111]. 

Written in standard 8080 assembly instructions to ensure universal portability across all 8080/8085/Z80 retro-hardware and modern emulators, this package provides a complete software development kit for low-level systems programming, embedded retro-computing, and application development [cite: 110, 111].

---

## 🌟 Key Features

### 1. Structured Control Flow Macros (`CONTROL.MAC`)
High-level control-flow constructs for assembly language without performance overhead [cite: 145]:
* **Conditional Blocks**: `IF_A_EQ`, `IF_A_NE`, `IF_A_LT`, `IF_A_GE`, `IF_CARRY`, `IF_ZERO`, `ELSE_BL`, `ENDIF_BL`, `ENDIF_ELSE`.
* **Structured Loops**: `WHILE_A_NE`, `WEND`, `DO_LOOP`, `DO_WHILE_A_NE`, and index-constrained `FOR_DCR` / `FOR_DCX` loops.
* **16-Bit Register Comparisons**: `COMPARE_HL_DE` for unsigned register pair evaluation.
* **High-Level Abstraction Wrappers**: Single-line macros for 32-bit math, BCD operations, floating-point math, 16.16 fixed-point arithmetic, CRC calculation, USART communication, heap allocation, string manipulation, argument parsing, and VT100 terminal commands.

### 2. Standard CP/M BDOS & File System Wrappers
* **Console & Peripheral Character I/O**: Wrappers for BDOS Functions 1–6 (`COUT`, `CIN`, `CSTAT`, `RAWIO_IN`, `LOUT`, `POUT`, `RIN`, `PRSTR`, `PRNL`) [cite: 19, 116, 117].
* **FCB Parsing & Line Input**: `GETLINE` for console text reading with CR stripping, and `PARSE_FCB` for manual command string parsing into 36-byte File Control Blocks with drive specifier and wildcard support [cite: 18, 117, 122].
* **Wildcard Directory Listing**: `DIR_LIST` scans disk directories using BDOS Search First/Next, automatically filtering deleted entries (`0E5H`) and stripping file attribute bits (`7FH`) [cite: 18, 117, 122].
* **File Operations**: Sequential record reading/writing, creation, deletion, renaming, DMA address setting, and sector pointer resets (`FOPEN`, `FCLOSE`, `FDELETE`, `FMAKE`, `FREAD`, `FWRITE`, `FSET_DMA`, `FSEEK_START`) [cite: 18, 117].
* **Disk Geometry Interrogation**: `PR_DRIVE_INFO` queries BDOS Function 31 to retrieve and display active Disk Parameter Block (DPB) parameters (sectors/track, allocation block size, directory capacity) [cite: 18, 117].
* **IOBYTE Device Redirection**: `GET_IOBYTE`, `SET_IOBYTE`, `PR_IOBYTE`, and field setters (`SET_CON_DEV`, `SET_RDR_DEV`, `SET_PUN_DEV`, `SET_LST_DEV`) to dynamically manipulate page-zero IOBYTE (`0003H`) mappings for logical devices (`CON:`, `RDR:`, `PUN:`, `LST:`) [cite: 19, 55, 117].

### 3. Extended Mathematics & Numeric Packages
* **32-Bit & 64-Bit Binary Integer Math**: Multi-byte addition, subtraction, shift-and-add multiplication, restoring division, sign extension, and formatted unsigned decimal string printing (`ADD32`, `MUL32`, `DIV32`, `PRDEC32`, `ADD64`, `MUL64`, `DIV64`, `PRDEC64`) [cite: 40, 110, 163, 217].
* **16.16 Signed Fixed-Point Arithmetic**: 32-bit fixed-point binary arithmetic (`FIX_ADD`, `FIX_SUB`, `FIX_MUL`, `FIX_DIV`), integer conversion, and 4-digit fractional decimal output (`PR_FIX`) [cite: 110].
* **Packed BCD Math Package**: Multi-byte packed Binary-Coded Decimal addition (`BCD_ADD`), 10's complement subtraction (`BCD_SUB`), `DAA` hardware acceleration, integer-to-BCD conversion (`INT_TO_BCD`), and leading-zero suppressed decimal printing (`PR_BCD`) [cite: 7, 113, 124, 125].
* **32-Bit Software Floating-Point Math**: 5-byte floating accumulator (`FAC1`, `FAC2`) supporting normalized arithmetic (`FP_ADD`, `FP_SUB`, `FP_MUL`, `FP_DIV`), integer conversion, and formatted ASCII output (`PR_FLOAT`) [cite: 110, 114].

### 4. Memory, String & Integrity Tools
* **Dynamic Heap Allocator**: First-fit memory manager (`MALLOC`, `FREE`, `REALLOC`, `CALLOC`) featuring 4-byte headers, TPA/BDOS memory boundary auto-detection, block splitting, contiguous free-list coalescing (`MALLOC_COALESCE`), and heap statistics reporting (`PR_HEAP_INFO`) [cite: 18, 47, 110].
* **Extended String Utilities**: Substring search (`STRSTR`), wildcard pattern matching (`STRMATCH` with `?` and `*`), in-place tokenization (`STRTOK`), whitespace trimming (`STRTRIM`), and case conversion (`STRUPR`, `STRLWR`) [cite: 124, 160, 214].
* **CRC-16-CCITT Data Integrity**: Bit-stream CRC-16 checksum calculation (`0x1021` polynomial) for memory buffers (`CRC16_BUF`) and raw disk files (`CRC16_FILE`) [cite: 44, 110].

### 5. Hardware Interfacing & Terminal Control
* **Intel 8251 USART Driver**: Hardware serial port setup (`UART_INIT`), dynamic runtime port remapping via self-modifying code (`UART_SET_PORTS`), polled I/O, and a 64-byte software RX ring buffer (`UART_BUF_PUT`, `UART_BUF_GET`) [cite: 110, 115].
* **Command-Line Argument Parser**: Parses CP/M command tail bytes at `0080H` into structured `ARGC`/`ARGV` arrays (`ARG_INIT`, `ARG_GET`, `ARG_FIND_FLAG`), supporting quoted strings and command-line flags [cite: 18, 22, 117].
* **VT100 / ANSI Terminal Control**: Terminal escape sequences for full-screen clearing (`VT_CLS`), cursor positioning (`VT_SET_CURSOR`), text formatting attributes (`VT_SET_ATTR`), foreground/background colors (`VT_SET_FG_COLOR`), and ANSI box drawing (`VT_BOX`).

---

## 📁 Repository Structure

* **`CPM22LIB-v13.ASM`**: The complete assembly function library containing all core subroutines, buffer areas, and system equates.
* **`CONTROL-v13.MAC`**: Macro library defining structured control constructs and high-level subroutine abstraction wrappers.
* **`DEMO-v13.ASM`**: Full interactive command shell demonstration program showing real-world usage of all library subroutines and macros.

---

## ⚙️ Compatibility & Build Instructions

### Toolchain Compatibility
This library is compatible with standard CP/M 8080/Z80 macro assemblers and development toolchains [cite: 19, 118, 144]:
* **Microsoft MACRO-80 (M80)** [cite: 118]
* **Digital Research MAC / RMAC** [cite: 19, 118]
* **Z88DK / SDCC (via assembly wrappers)** [cite: 32, 35, 127]

### Assembling & Linking (M80 / L80)
To assemble and link the demo shell under CP/M using Microsoft M80 and L80 [cite: 118]:

```text
A>M80 =DEMO-v13.ASM
A>L80 DEMO-v13,DEMO-v13/N/E
A>DEMO-v13
```

---

## 💻 Example Usage

```assembly
    INCLUDE CONTROL-v13.MAC

    ORG 0100H

START:
    LXI SP, STACK

    ; Print welcome message
    LXI HL, MSG_HELLO
    CALL PRSTR
    CALL PRNL

    ; Structured IF-THEN-ELSE example
    MVI A, 10
    IF_A_EQ 10, 1
        LXI HL, MSG_MATCH
        CALL PRSTR
        CALL PRNL
    ELSE_BL 1
        LXI HL, MSG_NO_MATCH
        CALL PRSTR
        CALL PRNL
    ENDIF_ELSE 1

    ; Perform 32-bit math using macros
    ADD32_MEM VAL1_32, VAL2_32
    PRDEC32_MEM VAL1_32
    CALL PRNL

    JMP WBOOT

MSG_HELLO:    DB 'CP/M Assembly Library Initialized$', 0
MSG_MATCH:    DB 'Value equals 10!', 0
MSG_NO_MATCH: DB 'Value does not match.', 0

VAL1_32:      DB 00H, 0E1H, 0F5H, 05FH ; 1,610,000,000
VAL2_32:      DB 00H, 0E1H, 0F5H, 05FH ; 1,610,000,000

    INCLUDE CPM22LIB-v13.ASM

    DS 32
STACK: EQU $
    END START
```

---

## 📜 License
Released under the **MIT License**. Free for use in open-source, commercial, and retro-computing projects.
