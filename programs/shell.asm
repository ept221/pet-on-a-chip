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

                ldi r2, text[l]
                ldi r3, text[h]
                call atoi

                ldi r4, foo[l]
                ldi r5, foo[h]
                call itoa

                ldi r2, foo[l]
                ldi r3, foo[h]
                call print_str


                ;ldi r2, prompt[l]
                ;ldi r3, prompt[h]
                ;call print_str

                ;ldi r0, 32
                ;ldi r1, 0
                ;ldi r2, text[l]
                ;ldi r3, text[h]
                ;call get_str

                ;ldi r4, yes[l]
                ;ldi r5, yes[h]
                ;call cmp_str

                ;cpi r6, 0
                ;bnz main_no

                ;ldi r2, yes[l]
                ;ldi r3, yes[h]
                ;call print_str
                ;br main

main_no:        ;ldi r2, no[l]
                ;ldi r3, no[h]
                ;call print_str
                ;br main
                hlt
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
                br itoa_end

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
; p2 holds the pointer to the string
atoi:           push r1
                push r2
                push r3
                push r4

                ldi r0, 0               ; initilize the result
                ldi r1, 10              ; initilize the multiplier

atoi_loop:      lri r4, p2
                cpi r4, 0
                bz atoi_end

                adi r4, -48             ; convert char to int

                push r2                 ; save the string pointer
                push r3

                call mult
                mov r0, r2              ; multiply the current result by 10
                add r0, r4              ; add the int of the char to the result

                pop r3                  ; retrieve the string pointer
                pop r2
                br atoi_loop            ; get another char

atoi_end:       pop r4
                pop r3
                pop r2
                pop r1
                ret
;******************************************************************************
                .data
text:           .string "134"
foo:            .string "    "
prompt:         .string "> "
you:            .string "You entered: "
yes:            .string "yes\n"
no:             .string "no\n"