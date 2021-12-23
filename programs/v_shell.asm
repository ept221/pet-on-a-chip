;******************************************************************************
                .define uart_baud, 0x0A
                .define uart_ctrl, 0x0B
                .define uart_buffer, 0x0C

                .define dir_reg, 0x00
                .define port_reg, 0x01
                .define pin_reg, 0x02

                .define gpu_addr, 0x2000
                .define gpu_ctrl_reg, 0x80

                .define newline, 10
                .define backspace, 8
                .define underscore, 95
                .define space, 32
;******************************************************************************         
                .code

init:           ldi r14, 0x00           ; setup the stack pointer
                ldi r15, 0x07

                ldi r0, 8               ; set the baud rate to 115200
                out r0, uart_baud       

                ldi r0, 0b00011100      ; setup the gpu
                out r0, gpu_ctrl_reg

                ldi r12, gpu_addr[l]    ; setup the pointer to the v-ram
                ldi r13, gpu_addr[h]
                ldi r9, 0               ; the col counter

                ldi r0, 0b11111
                out r0, dir_reg         ; Set the first 5 bits of the i/o port to output

                ldi r2, welcome[l]      ; print the welcome
                ldi r3, welcome[h]
                call print_str
                call paint_str
                ;***************************************************************

loop:           ldi r2, prompt[l]       ; print the prompt
                ldi r3, prompt[h]
                call print_str
                call paint_str

                ldi r0, 11              ; get user input
                ldi r2, buffer[l]
                ldi r3, buffer[h]
                call get_str
                call strip_str          ; strip the string

                ldi r4, cmd_hlp[l]      ; if "h" run help
                ldi r5, cmd_hlp[h]
                call str_cmp
                cpi r6, 0
                bz help

                ldi r4, cmd_peek[l]     ; if "peek" run peek
                ldi r5, cmd_peek[h]
                call str_cmp
                cpi r6, 0
                bz peek

                ldi r4, cmd_poke[l]     ; if "poke" run poke
                ldi r5, cmd_poke[h]
                call str_cmp
                cpi r6, 0
                bz poke

                ldi r4, cmd_clear[l]    ; if "clear" run clear
                ldi r5, cmd_clear[h]
                call str_cmp
                cpi r6, 0
                bz clear

                br loop                 ; else, go get another input
                ;**************************************************************
help:           ldi r2, hlp_msg_1[l]    ; print help message
                ldi r3, hlp_msg_1[h]
                call print_str
                call paint_str
                br loop
                ;**************************************************************
peek:           ldi r2, peek_msg_1[l]   ; prompt for address
                ldi r3, peek_msg_1[h]
                call print_str
                call paint_str

                ldi r0, 11              ; get user input
                ldi r2, buffer[l]
                ldi r3, buffer[h]
                call get_str
                call strip_str          ; strip the string

                ldi r4, buffer[l]
                ldi r5, buffer[h]
                call atoi               ; parse the int

                mov r2, r0              ; copy the int into the lower reg of the pair
                ldi r3, 0x10            ; put the i/o offset into the upper reg of the pair
                ldr r0, p2, 0           ; read the register

                call itoa
                ldi r2, buffer[l]
                ldi r3, buffer[h]
                call print_str          ; print the register's contents
                call paint_str

                ldi r0, newline
                call print_char
                call paint_char
                br loop
                ;**************************************************************
poke:           ldi r2, poke_msg_1[l]   ; prompt for address
                ldi r3, poke_msg_1[h]
                call print_str
                call paint_str

                ldi r0, 11              ; get user input
                ldi r2, buffer[l]
                ldi r3, buffer[h]
                call get_str
                call strip_str          ; strip the string

                ldi r4, buffer[l]
                ldi r5, buffer[h]
                call atoi               ; parse the int
                mov r6, r0              ; copy the address int to r6

                ldi r2, poke_msg_2[l]   ; prompt for data
                ldi r3, poke_msg_2[h]
                call print_str
                call paint_str

                ldi r0, 11              ; get user input
                ldi r2, buffer[l]
                ldi r3, buffer[h]
                call get_str
                call strip_str          ; strip the string

                ldi r4, buffer[l]
                ldi r5, buffer[h]
                call atoi               ; parse the int

                mov r2, r6              ; move the address int to the lower reg in the pair
                ldi r3, 0x10            ; put the i/o offset into the upper reg of the pair
                str r0, p2, 0           ; write to the register

                br loop
                ;**************************************************************
clear:          ldi r12, gpu_addr[l]    ; setup the pointer to the v-ram
                ldi r13, gpu_addr[h]
                ldi r9, 0               ; the col counter
                ldi r0, 32              ; This clears the screen by filling
                ldi r2, 0x60            ; it up with spaces
                ldi r3, 0x09

clear_p:        sri r0, p12
                api p2, -1
                cpi r3, 0
                bnz clear_p
                cpi r2, 0
                bnz clear_p

                ldi r12, gpu_addr[l]    ; setup the pointer to the v-ram
                ldi r13, gpu_addr[h]
                br loop
                ;**************************************************************
                br loop
;******************************************************************************
; scrolls the screen and adjusts the cursor
scroll:         push r0

                in r0, gpu_ctrl_reg
                ori r0, 0b00100000
                out r0, gpu_ctrl_reg

scroll_p:       in r0, gpu_ctrl_reg
                ani r0, 32
                bnz scroll_p
                api p12, -80

                pop r0
                ret
;******************************************************************************
; print char prints a char over the UART. The char must be placed in r0.
; Additionally the UART must already be configured.
print_char:     push r1

print_char_p:   in r1, uart_ctrl
                ani r1, 2
                bz print_char_p

                out r0, uart_buffer

print_char_ret: pop r1
                ret
;******************************************************************************
; paint_char
paint_char:     cpi r0, newline         ; check to see if the char is a newline
                bz paint_char_nl
                cpi r0, backspace
                bz paint_char_bs
                
                sri r0, p12             
                cpi r9, 80
                bnz paint_char_reg
                ldi r9, 0
                br paint_char_ret

paint_char_reg: adi r9, 1
                br paint_char_ret

paint_char_nl:  sub r12, r9             ; need to go back to the beginning of the line
                aci r13, -1             ; this is a hack that does r13 - 0 with borrow
                api p12, 80             ; then add 80 to go to the next line
                ldi r9, 0               ; and reset the column counter to 0
                br paint_char_ret

paint_char_bs:  api p12, -1             ; move back the char pointer
                ldi r5, 32              
                str r5, p12, 0          ; and overwrite the data with a space
                
                cpi r9, 0               ; if we're at the beginning of the row
                bnz paint_char_sub
                ldi r9, 79              ; set column counter to end of previous row
                br paint_char_ret

paint_char_sub: adi r9, -1              ; else decriment the column counter

paint_char_ret: ret
;******************************************************************************
; paint_str prints a string to the VGA screen at the current cursor position.
; A pointer to the strin must be in the register pair p2.
paint_str:      push r0
                push r2
                push r3

paint_str_p:    lri r0, p2 
                cpi r0, 0
                bz paint_str_ret
                call paint_char
                br paint_str_p

paint_str_ret:  pop r3
                pop r2
                pop r0
                ret
;******************************************************************************
; print_str prints a string over the UART. A pointer to the string must be in
; the register pair p2. Additionally, the UART must already be configured.
print_str:      push r0
                push r1
                push r2
                push r3

print_str_p:    lri r0, p2              ; check for end of string
                cpi r0, 0
                bz print_str_ret
                call print_char
                br print_str_p

print_str_ret:  pop r3
                pop r2
                pop r1
                pop r0
                ret
;******************************************************************************
; get_str reads a newline terminated string from the UART and echos it back.
; A pointer to the buffer must be in the register pair p2, and the length of
; the buffer must be in the register pair p0.
get_str:        push r0
                push r1
                push r2
                push r3
                push r4
                push r5
                push r6
                push r7

                ldi r5, underscore      ; print the cursor         
                str r5, p12, 0

                api p0, -2              ; subtract off one for the null char, and one for the nl
                mov r6, r0              ; create backup of the length 
                mov r7, r1

get_str_rx:     in r5, uart_ctrl        ; poll for full rx buffer
                ani r5, 1
                bz get_str_rx

                in r4, uart_buffer      ; read the char

                cpi r4, backspace       ; check if the char was backspace
                bnz get_str_not_bs      ; if it is wasn't, go do not_bs
                cmp r0, r6              ; and if p0 != p6 (part1)
                bnz get_str_bs          ; then go do backspace
                cmp r1, r7              ; and if p0 != p6 (part2)
                bz get_str_rx           ; if p0 == p6 then backspace would go past buffer, so go get another char

get_str_bs:     api p2, -1              ; else, decriment the buffer pointer
                api p0, 1               ; incriment the length
                ldi r5, space           ; overwrite the cursor with a space   
                str r5, p12, 0
                br get_str_tx           ; and echo the backspace

get_str_not_bs: cpi r4, newline
                bnz get_str_not_nl
                ldi r5, space           ; overwrite the cursor with a space   
                str r5, p12, 0
                br get_str_store

get_str_not_nl: mov r5, r0              ; check if p0 == 0 (i.e. we are at the end of the buffer)
                or r5, r1
                bz get_str_rx           ; go wait for a newline or backspace if at the end of the buffer

get_str_store:  sri r4, p2              ; store the char in the provided buffer
                adi r0, -1              ; decriment the length counter

get_str_tx:     push r0
                mov r0, r4
                call print_char
                call paint_char
                pop r0

                cpi r4, newline         ; return if the char was a newline
                bz get_str_ret
                ldi r5, underscore      ; print the cursor           
                str r5, p12, 0
                br get_str_rx

get_str_ret:    ldi r4, 0               ; add the null terminator to the string
                str r4, p2, 0

                pop r7
                pop r6
                pop r5
                pop r4
                pop r3
                pop r2
                pop r1
                pop r0
                ret
;******************************************************************************
; strip_str strips the newline from a string. A pointer to the string must
; be in register pair p2.
strip_str:      push r0
                push r2
                push r3

strip_str_p:    lri r0, p2              ; look for the newline
                cpi r0, newline
                bnz strip_str_p

                api p2, -1              ; point to the newline
                ldi r0, 0
                str r0, p2, 0           ; overwrite the newline with a null

                pop r3
                pop r2
                pop r0
                ret
;******************************************************************************
; str_cmp compares two strings. The first string is pointed to by p2, and the
; second string is pointed to by p4. If the strings are equal r6 is set to 0x00,
; otherwise it is set to 0xff
str_cmp:        push r0
                push r1
                push r2
                push r3
                push r4
                push r5

                ldi r6, 0xff
str_cmp_loop:   lri r0, p2
                lri r1, p4

                cmp r0, r1
                bnz str_cmp_ret
                cpi r0, 0
                bnz str_cmp_loop

                ldi r6, 0

str_cmp_ret:    pop r5
                pop r4
                pop r3
                pop r2
                pop r1
                pop r0
                ret
;******************************************************************************
; r0 is the multiplicand
; r1 is the multiplier
; r2 and r3 will hold the results
        
mult:           push r0
                push r1
                push r4
                push r5

                ldi r5, 8               ; counter
                ldi r2, 0               ; initilize the result to zero
                ldi r3, 0
                ldi r4, 0               ; initilize the extended multiplicand to zero

mult_loop:      cpi r5, 0               ; check if we have completed 8 iterations
                bz mult_end

                srl r1                  ; shift the multiplier to the right
                bnc mult_shift          ; don't add if the lsb was zero

                add r2, r0              ; add the multiplicand to the result
                adc r3, r4

mult_shift:     sll r0                  ; shift the multiplicand to the left
                rlc r4
                
                adi r5, -1              ; decriment the counter
                br mult_loop

mult_end:       pop r5
                pop r4
                pop r1
                pop r0
                ret
;******************************************************************************
; r0 holds the dividend
; r1 holds the divisor
; r2 holds the quotient
; r3 holds the remainder

divmod:         push r0
                push r4

                ldi r3, 0           ; initilize the remander to zero
                ldi r4, 8           ; initilize the counter
                csr 0

divmod_loop:    pus
                cpi r4, 0           ; check the counter
                bz divmod_end       ; branch if we've shifted all 8 times
                adi r4, -1
                pos
                
                rlc r0              ; shift the dividend left and bring in the next bit of the quotient
                rlc r3              ; shift the remainder left and bring in the next bit of the remainder

                sub r3, r1          ; subtract the divisor from the remainder
                bc divmod_loop      ; don't restore if the result was positive
                
                add r3, r1          ; else restore
                csr 0
                br divmod_loop

divmod_end:     pos

                rlc r0              ; get the last bit of the quotient
                mov r2, r0          ; copy the quotient into r2

                pop r4              ; restore the counter reg
                pop r0              ; restore the divisor
                ret
;******************************************************************************
; r0 holds the int
; p4 holds the string pointer
itoa:           push r0
                push r1
                push r2
                push r3
                push r4
                push r5
                push r6
                push r7

                cpi r0, 0           ; check to see if the int is zero
                bnz itoa_nz         ; if it isn't, proceed normally
                ldi r0, 48          ; otherwise create the string "0\0"
                sri r0, p4
                ldi r0, 0
                sri r0, p4
                br itoa_ret

itoa_nz:        ldi r1, 10          ; set divisor to 10
                mov r6, r4
                mov r7, r5

itoa_loop:      cpi r0, 0           ; check if dividend is zero
                bz itoa_end

                call divmod
                adi r3, 48          ; convert remainder to char
                sri r3, p4          ; store the char
                mov r0, r2          ; make the quotient the new dividend
                br itoa_loop

itoa_end:       sri r0, p4          ; store the null char
                api p4, -2          ; now p4 points to the last non-null char

itoa_flip:      cmp r7, r5          ; reverse the string
                bc itoa_ret
                cmp r6, r4
                bc itoa_ret

                ldr r0, p6, 0
                ldr r1, p4, 0
                str r0, p4, 0
                str r1, p6, 0

                api p6, 1
                api p4, -1
                br itoa_flip

itoa_ret:       pop r7
                pop r6
                pop r5
                pop r4
                pop r3
                pop r2
                pop r1
                pop r0
                ret
;******************************************************************************
; r0 will hold the result
; p4 holds the pointer to the string
atoi:           push r1
                push r2
                push r3
                push r4
                push r5
                push r6

                ldi r0, 0               ; initilize the result
                ldi r1, 10              ; initilize the multiplier

atoi_loop:      lri r6, p4              ; get a char from the string
                cpi r6, 0               ; check if it is null
                bz atoi_sane            ; if it is, finish

                cpi r6, 48
                bn atoi_bad
                cpi r6, 57
                bc atoi_bad       

                adi r6, -48             ; convert char to int

                call mult               ; multiply the current result by 10
                mov r0, r2              
                add r0, r6              ; add the int of the char to the result

                br atoi_loop            ; get another char

atoi_bad:       ldi r0, 0x00

atoi_sane:      pop r6
                pop r5
                pop r4
                pop r3
                pop r2
                pop r1
                ret
;******************************************************************************
                .data
welcome:        .ostring "Welcome to Pet on a Chip!\n"
                .string  "Type \"h\" for help.\n"

prompt:         .string "> "

cmd_peek:       .string "peek"
cmd_poke:       .string "poke"
cmd_clear:      .string "clear"
cmd_hlp:        .string "h"

hlp_msg_1:      .ostring "Type \"peek\" to read an i/o register\n"
                .ostring "Type \"poke\" to write to an i/o register\n"
                .ostring "Type \"clear\" to clear the screen\n"
                .string  "Type \"h\" to display this message\n"

peek_msg_1:     .string "Enter an i/o address to read from:\n> "

poke_msg_1:     .string "Enter an i/o address to write to:\n> "
poke_msg_2:     .string "Enter the data to write:\n> "

buffer:         .ds 11