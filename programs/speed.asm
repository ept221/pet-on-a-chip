;******************************************************************************
        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C

        .define motor_control, 0x0D
        .define motor_enable, 0x0E
        .define motor_pwm0, 0x0F
        .define motor_pwm1, 0x10
        .define motor_speed0, 0x11
        .define motor_speed1, 0x12

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0014
        .define top_isr_vector, 0x001E
;******************************************************************************        
        .code

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

        ldi r0, 0xff
        out r0, motor_enable

loop:   in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        bz loop               

        in r0, uart_buffer      ; capture the data

        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r1, 0b00000110
        out r1, motor_control
        cpi r0, 0
        bnz loop
        out r0, motor_control
        br loop