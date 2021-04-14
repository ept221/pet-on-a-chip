;******************************************************************************
        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C

        .define motor_control, 0x0D
        .define motor_enable, 0x0E
        .define motor_pwm0, 0x0F
        .define motor_pwm1, 0x10

        .define servo, 0x11
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

write:  out r1, motor_pwm0
        out r1, motor_pwm1
        out r0, motor_control
        br loop1