;******************************************************************************
                .define uart_baud, 0x0A
                .define uart_ctrl, 0x0B
                .define uart_buffer, 0x0C
;******************************************************************************         
                .code

main:           ldi r0, 8
                out r0, uart_baud       ; set the baud rate to 115200

                ldi r14, 0xff           ; setup the stack pointer
                ldi r15, 0x00

                mov r12, r14            ; setup the frame pointer
                mov r13, r15

                ldi r2, prompt[l]
                ldi r3, prompt[h]
                call print_str

                ldi r0, 32
                ldi r1, 0
                ldi r2, text[l]
                ldi r3, text[h]
                call get_str

                ldi r4, yes[l]
                ldi r5, yes[h]
                call cmp_str

                cpi r6, 0
                bnz main_no

                ldi r2, yes[l]
                ldi r3, yes[h]
                call print_str
                br main

main_no:        ldi r2, no[l]
                ldi r3, no[h]
                call print_str
                br main
;******************************************************************************
; print_str prints a string over the UART. A pointer to the string must be in
; the register pair p2. Additionally, the UART must already be configured.
print_str:      push r0
                push r1
                push r2
                push r3

print_str_p:    in r0, uart_ctrl        ; poll for empty buffer
                ani r0, 2
                bz print_str_p

                lri r1, p2              ; check for end of string
                cpi r1, 0
                bz print_str_ret

                out r1, uart_buffer     ; print the char
                br print_str_p

print_str_ret:  pop r3
                pop r2
                pop r1
                pop r0
                ret
;******************************************************************************
; get_str reads a newline terminated string from the UART and echos it back.
; A pointer to the  buffer must be in the register pair p2, and the length of
; the buffer must be in the register pair p0.
get_str:        push r0
                push r1
                push r2
                push r3
                push r4
                push r5
                push r6
                push r7

                api p0, -2              ; subtract off one for the null char, and one for the nl
                mov r6, r0              ; create backup of the length 
                mov r7, r1

get_str_rx:     in r5, uart_ctrl        ; poll for full rx buffer
                ani r5, 1
                bz get_str_rx

                in r4, uart_buffer      ; read the char

                cpi r4, 8               ; check if the char was backspace
                bnz get_str_not_bs      
                cmp r0, r6              ; and if p0 != p6
                bnz get_str_bs
                cmp r1, r7
                bnz get_str_bs
                br get_str_rx

get_str_bs:     api p2, -1              ; else, decriment the buffer pointer
                api p0, 1               ; incriment the length
                br get_str_tx           ; and echo the backspace

get_str_not_bs: mov r5, r0              ; if p0 is zero and the char was not a newline
                or r5, r1
                bnz get_str_store  
                cpi r4, 10
                bz get_str_store
                br get_str_rx           ; get another char

get_str_store:  sri r4, p2              ; store the char in the provided buffer
                adi r0, -1              ; decriment the length counter

get_str_tx:     in r5, uart_ctrl        ; poll for empty rx buffer
                ani r5, 2
                bz get_str_tx

                out r4, uart_buffer     ; echo the char

                cpi r4, 10              ; return if the char was a newline
                bz get_str_ret
                br get_str_rx           ; else go read another char

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
; cmp_str compares two strings. The first string is pointed to by p2, and the
; second string is pointed to by p4. If the strings are equal r6 is set to 0x00,
; otherwise it is set to 0xff
cmp_str:        push r0
                push r1
                push r2
                push r3
                push r4
                push r5

                ldi r6, 0xff
cmp_str_loop:   lri r0, p2
                lri r1, p4

                cmp r0, r1
                bnz cmp_str_ret
                cpi r0, 0
                bnz cmp_str_loop

                ldi r6, 0

cmp_str_ret:    pop r5
                pop r4
                pop r3
                pop r2
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

                pop r0              ; restore the counter reg
                pop r4              ; restore the dividend
                ret
;******************************************************************************
                .data
text:           .string "                                "
prompt:         .string "> "
you:            .string "You entered: "
yes:            .string "yes\n"
no:             .string "no\n"