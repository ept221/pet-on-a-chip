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
;******************************************************************************
        .code

        ldi r0, 8               ; set the baud rate to 115200
        out r0, uart_baud

        ldi r0, 128             ; move the servo straight ahead
        out r0, servo

start:  ldi r1, 4
        ldi r2, 0
        ldi r3, 0
;******************************************************************************
read:   ldi r0, 0x01            ; trigger a reading
        out r0, sonar_control
;******************************************************************************
poll0:  in r0, sonar_control    ; poll for reading ready
        ani r0, 1
        bnz poll0
;******************************************************************************
        in r0, sonar_range      ; read the sonar range

        add r2, r0              ; add it to the p2 pair
        aci r3, 0

        adi r1, -1              ; decriment the counter
        bnz read                ; get another reading if not done
;******************************************************************************
        srl r3                  ; divide p2 by 2
        rrc r2

        srl r3                  ; divide p2 by 2
        rrc r2
;******************************************************************************
poll1:  in r0, uart_ctrl        ; poll for empty tx buffer
        ani r0, 2
        bz poll1

        out r2, uart_buffer     ; write the range to the uart
;******************************************************************************
        br start