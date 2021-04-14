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

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0014
        .define top_isr_vector, 0x001E
;******************************************************************************
        .code

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud
;******************************************************************************
start:  ldi r0, 0x01            ; trigger a reading
        out r0, sonar_control
;******************************************************************************
poll0:  in r0, sonar_control    ; poll for reading ready
        ani r0, 1
        bnz poll0
;******************************************************************************
poll1:  in r0, uart_ctrl        ; poll for empty tx buffer
        ani r0, 2
        bz poll1

        in r0, sonar_range      ; read the range
        out r0, uart_buffer     ; write the range to the uart
;******************************************************************************
        br start