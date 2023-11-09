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
        ldi r0, 1               ; set pin 1 to output
        out r0, dir_reg 

        ldi r14, 0xff           ; setup the stack pointer

        ldi r0, isr[l]                  ; setup the top isr vector
        out r0, top_isr_vec_reg_l
        ldi r0, isr[h]
        out r0, top_isr_vec_reg_h

        ldi r0, 0b00011110      ; setup the gpu control register
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]     ; setup the vram pointer
        ldi r3, gpu_addr[h]

        ssr 8                   ; enable interrupts
loop:   br loop                 ; do nothing and wait for an interrupt
;******************************************************************************
isr:    in r0, pin_reg          ; read pin 1
        xoi r0, 1               ; flip the bit
        out r0, port_reg        ; toggle pin 1
        
        ldi r0, 32              ; load a space
        sri r0, p2              ; write the space to the screen and move to the right
        cpi r2, 80
        bnz j
        ldi r2, 0

j:      ldi r0, 65              ; load "A"
        str r0, p2, 0           ; write A to the screen

end:    ssr 8                   ; enable interrupts
        ret                     ; return
;******************************************************************************