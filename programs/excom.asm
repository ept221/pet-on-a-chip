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

        .define sonar_control, 0x12
        .define sonar_range, 0x13

        .define excom, 0x14

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;******************************************************************************
        .code

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

        ldi r0, 0xff
        out r0, motor_enable
        ldi r0, 40
        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r0, 0b00000101
        out r0, motor_control
;******************************************************************************
poll1:  in r0, uart_ctrl        ; poll for empty tx buffer
        ani r0, 2
        bz poll1

        in r0, excom            ; read the range
        out r0, uart_buffer     ; write the range to the uart
;******************************************************************************
        br poll1