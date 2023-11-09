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

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

        ldi r0, 128
        out r0, servo

        ldi r0, 0xff
        out r0, motor_enable

        ldi r3, 40

loop1:  in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        bz loop1                

        in r0, uart_buffer      ; capture the data

        cpi r0, 115             ; 's'
        bz off
        cpi r0, 97              ; 'a'
        bz ccw
        cpi r0, 100             ; 'd'
        bz cw
        cpi r0, 119             ; 'f'
        bz f
        cpi r0, 120             ; 'x'
        bz b
        br loop1

off:    ldi r0, 0b00001111
        ldi r1, 0
        br write

ccw:    ldi r0, 0b00001001
        mov r1, r3
        br write

cw:     ldi r0, 0b00000110
        mov r1, r3
        br write

f:      ldi r0, 0b00000101
        mov r1, r3
        br write

b:      ldi r0, 0b00001010
        mov r1, r3
        br write

write:  out r1, motor_0_sp
        out r1, motor_1_sp
        out r0, motor_control
        br loop1