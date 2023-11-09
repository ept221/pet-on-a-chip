# Pet On A Chip
Pet on a chip is a project which condenses the control logic the robot described in Frank DaCosta's book "How to Build Your Own Working Robot Pet" onto a single FPGA. More details, pictures, and videos can be found on this [blog post](https://ezrasrobots.wordpress.com/2021/07/07/pet-on-a-chip/).

## tinySoC
tinySoC is a small system on a chip responsible for controlling the robot. It consists of an 8-bit CPU, an 80 column VGA graphics controller, a programmable interrupt controller, GPIO, counter/timer peripherals, dual closed loop motor controllers, a servo controller, a sonar controller, and a UART, all implemented on an iCE40 FPGA. It also comes with an assembler and utilities for loading programs into the chip's internal block memory without having to rerun synthesis and place-and-route.

## The CPU
![datapath](resources/datapath.jpg)
The CPU is an 8-bit RISC core, with a Harvard architecture. It has a 16-bit wide instruction memory, an 8-bit wide data memory, and both have a 16-bit address. The CPU has 16 general purpose 8-bit registers along with a 4-bit status register. The processor is not fully pipelined, but does fetch the next instruction while executing the current one. Most instructions execute in a single clock cycle, but a few take two or three.

## The GPU
![gpu](resources/gpu.jpg)
The GPU operates in a monochrome 80 column text mode, and outputs a VGA signal at a resolution of 640 by 480 at 60 frames per second. The GPU contains an ASCII buffer which the user can write to in order to display messages on the screen. A control register allows the user to set the text to one of 7 colors, and to enable an interrupt to the CPU which fires every time a frame finishes and enters the blanking period. Not shown in the diagram is some control logic that allows the screen to be scrolled upwards by writing to the control register.

## The Instruction Set
![instruction set part 1](resources/ISA_Part_1.png)
![instruction set part 2](resources/ISA_Part_2.png)

## The PCBs
The main board:
![Delux Pet on a Chip](resources/delux_pet_on_a_chip.jpg)
The expantion board:
![Daughter Board](resources/daughter.jpg)
## The Assembler

The assembler is case insensitive.

### Comments
Comments begin with semicolons.
```assembly
        .code
        ldi r0, 1 ; This is a comment
```

### Constants
Constants are in decimal by default, but hexadecimal and binary are also supported. Constants can also be negative and are stored in two's complement form when assembled.
```assembly
        .code
        ldi r0, 10     ; Decimal constant
        ldi r0, 0x0A   ; Hexadecimal constant
        ldi r0, 0b1010 ; Binary constant
        ldi r0, -10    ; A negative constant
```

### Label Definitions
Label definitions may be any string ending with a colon, as long as the string is not in the form of a constant or is one of the reserved keywords

```assembly
        .code
        ldi r0, 10
loop:   adi r0, -1
        bnz loop
        hlt
```

### Directives

#### .code
Specifies that the following lines are code to be assembled and placed in instruction memory.

#### .data
Specifies that the following lines are data to be placed in data memory.

#### .org
Sets the origin to the given address. Only forward movement of the origin is permitted.
```assembly
        .code
        ldi r0, 1
        out r0, 0
        br foo
        
        .org 0x0B
foo:    out r0, 1
        hlt

;*************************************************************************
; Assembles to the following:
; Address        Label          Code                     Source
; ------------------------------------------------------------------------
; 0x0000                        0b0000000000010001       LDI R0, 1        
; 0x0001                        0b0000000000001001       OUT R0, 0        
; 0x0002                        0b0000000010011110       BR FOO           
; 0x000B         FOO:           0b0000000000011001       OUT R0, 1        
; 0x000C                        0b1111111111111111       HLT 
```

#### .db
Writes one or more data bytes sequentially into data memory.
```assembly
        .data
        .db 0x01, 0x44, 0x73

;*************************************************************************
; Assembles to the following:
; Address        Label          Data
; ------------------------------------------
; 0x0000                        0x01
; 0x0001                        0x44
; 0x0002                        0x73
```

#### .ds
Defines a block of space in the data memory. This is useful for allocating room for a buffer.
```assembly
        .data
        .db 5
        .ds 3
        .db 7

;*************************************************************************
; Assembles to the following:
; Address        Label          Data
; ------------------------------------------
; 0x0000                        0x05                                         
; 0x0004                        0x07 
```

#### .string
Writes a null terminated ASCII string into data memory. Double quotes and backslashes must be escaped with a backslash.

```assembly
        .data
        .string "The robot says \"Hi!\""
        
;*************************************************************************
; Assembles to the following:
; Address        Label          Data
; ------------------------------------------
; 0x0000                        0x54
; 0x0001                        0x68
; 0x0002                        0x65
; 0x0003                        0x20
; 0x0004                        0x72
; 0x0005                        0x6F
; 0x0006                        0x62
; 0x0007                        0x6F
; 0x0008                        0x74
; 0x0009                        0x20
; 0x000A                        0x73
; 0x000B                        0x61
; 0x000C                        0x79
; 0x000D                        0x73
; 0x000E                        0x20
; 0x000F                        0x22
; 0x0010                        0x48
; 0x0011                        0x69
; 0x0012                        0x21
; 0x0013                        0x22
; 0x0014                        0x00
```

#### .ostring
Write a ASCII string into data memory. The string is open, which means that it is not null terminated. This is useful if you have a long string that you want to split up into multiple lines in the assembly source file.

```assembly
        .data
        .ostring "Hi! "
        .string  "Bye!"

;*************************************************************************
; Assembles to the following:
; Address        Label          Data
; ------------------------------------------
; 0x0000                        0x48
; 0x0001                        0x69
; 0x0002                        0x21
; 0x0003                        0x20
; 0x0004                        0x42
; 0x0005                        0x79
; 0x0006                        0x65
; 0x0007                        0x21
; 0x0008                        0x00
```

#### .define
Equates a symbol with a number.
```assembly
        .code
        .define foo, 5
        ldi r0, foo
        hlt
        
;*************************************************************************
; Assembles to the following:        
; Address        Label          Code                     Source
; ------------------------------------------------------------------------
; 0x0000                        0b0000000001010001       LDI R0, FOO     
; 0x0001                        0b0000000011110000       HLT  
```

### Expressions
Any time an instruction or directive requires a numerical argument, an expression can be used.
Supported operations inside expressions include addition and subtraction. The location counter $ is also made available. If an instruction is two bytes long then $ refers to the address of the second byte. Expressions may contain symbols, but must resolve within two passes of the assembler, and if used for directive arguments, must resolve in a single pass.

```assembly
; Example resolution in one pass
        .code
        .define foo, 5
        ldi r0, foo + 7
        hlt

;*************************************************************************
; Assembles to the following:
; Address        Label          Code                     Source
; ------------------------------------------------------------------------
; 0x0000                        0b0000000011000001       LDI R0, FOO + 7
; 0x0001                        0b0000000011110000       HLT
```
```assembly
; Example resolution in two passes
        .code
        ldi r0, foo + 7
        hlt
        .define foo, 5

;*************************************************************************
; Assembles to the following:
; Address        Label          Code                     Source
; ------------------------------------------------------------------------
; 0x0000                        0b0000000011000001       LDI R0, FOO + 7
; 0x0001                        0b0000000011110000       HLT
```
```assembly
; Example resolution in two passes with $
        .code
        ldi r0, $
        jmp $ + foo
        .define foo, 2
        nop
        nop
        nop
        hlt

;*************************************************************************
; Assembles to the following:
; Address        Label          Code                     Source
; ------------------------------------------------------------------------
; 0x0000                        0b0000000000000001       LDI R0, $
; 0x0001                        0b0000000010111000       JMP $ + FOO
; 0x0002                        0b0000000000000100
; 0x0003                        0b0000000000000000       NOP
; 0x0004                        0b0000000000000000       NOP
; 0x0005                        0b0000000000000000       NOP
; 0x0006                        0b0000000011110000       HLT
```
## The Development Process
To perform synthesis and place-and-route, run:
```bash
make synth
make pnr
```
To assemble a demo program, run:
```bash
./assemble programs/shell.asm shell
```
To upload the configuration bitstream for the previously assembled program, run:
```bash
./upload shell
```
You will now be able to interact with a basic shell over the UART at 115200 baud. Additionally, the output will also be sent over the VGA interface.

## Requirements
- Yosys for synthisis
- nextpnr for place and route
- icestorm tools for icebram and iceprog

## Peripherals

There are a variety of memory mapped peripherals included in the system. The memory map is configured in `soc/src/d_ram_and_io/d_ram_and_io.v`. Currently addresses `0x0000` to `0x07FF` are mapped to data ram. The peripherals are mapped from `0x1000` to `0x10FF`. The instructions `in` and `out` are designed to allow for quickly and easily reading and writing to peripherals within this address range. For example, `out r1, 5` writes the value in r1 to address `0x1005`. In contrast, when reading and writing to data memory, or writing to the graphics buffer which is from `0x2000` to `0x2960`, `in` and `out` cannot be used, and the other load and store instructions must be used instead, which require setting up a pointer in a register pair to the memory location you want to operate on.

### GPIO
|Address|Register|r/w|Description|
|-------|--------|---|-----------|
|0x0000|Direction|r/w|Sets GPIO pins to input or output|
|0x0001|Port|r/w|Write values to be outputed|
|0x0002|Pin|r|Read values on pins|
