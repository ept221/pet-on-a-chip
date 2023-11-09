;*************************************************
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
;*************************************************      
        .code

        ldi r0, 0b00001100
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]

stable: in r0, gpu_ctrl_reg
        ani r0, 0x80
        bz stable

        ldi r0, text[l]
        ldi r1, text[h]

loop:   lri r4, p0
        cpi r4, 0
        bz end
        sri r4, p2
        br loop

end:    hlt
;*************************************************
        .data

text:   .string "GitHub repo at: https://github.com/ept221/pet-on-a-chip"
;*************************************************