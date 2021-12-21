;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C

        .define motor_control, 0x0D
        .define motor_enable, 0x0E
        .define motor_pwm0, 0x0F
        .define motor_pwm1, 0x10

        .define servo, 0x11

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;******************************************************************************

        .code

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

loop1:  in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        bz loop1                

        in r0, uart_buffer      ; capture the data

loop2:  in r1, uart_ctrl        ; poll for empty tx buffer
        ani r1, 2
        bz loop2
        out r0, uart_buffer     ; echo the char back over the uart

        out r0, servo           ; write the data to the servo
        br loop1
