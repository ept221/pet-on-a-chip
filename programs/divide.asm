;******************************************************************************
                .define dir_reg, 0x00
                .define port_reg, 0x01
                .define pin_reg, 0x02

                .define prescaler_l, 0x03
                .define prescaler_h, 0x04
                .define count_ctrl, 0x05

                .define uart_baud, 0x09
                .define uart_ctrl, 0x0A
                .define uart_buffer, 0x0B

                .define motor_control, 0x0C
                .define motor_enable, 0x0D
                .define motor_0_sp, 0x0E
                .define motor_1_sp, 0x0F
                .define motor_0_fb, 0x10
                .define motor_1_fb, 0x11

                .define servo, 0x12

                .define sonar_control, 0x13
                .define sonar_range, 0x14

                .define top_isr_vec_reg_l, 0x15
                .define top_isr_vec_reg_h, 0x16

                .define gpu_addr, 0x2000
                .define gpu_ctrl_reg, 0x80
;******************************************************************************

                .code

                ldi r14, 0xff           ; setup the stack pointer
                ldi r15, 0x00

                ldi r0, 103             ; set the baud-rate to 9600
                out r0, uart_baud

                ldi r0, 253             ; dividend
                ldi r1, 7               ; divisor
                call divmod

loop:           in r5, uart_ctrl
                ani r5, 2
                bz loop                  ; poll for empty buffer

                out r2, uart_buffer      ; print the quotient

                hlt
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
                pop r0              ; restore the dividend
                ret
;******************************************************************************