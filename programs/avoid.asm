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

        ldi r14, 0xff                   ; setup stack pointer
        ldi r15, 0x00

        ldi r0, 128                     ; setup servo
        out r0, servo

        ldi r0, 0xff                    ; enable motor
        out r0, motor_enable

        ldi r0, 0b00011111
        out r0, dir_reg
        out r0, port_reg

button: in r0, pin_reg
        ani r0, 0b00100000
        bnz button        

run:    call forwards

sense0: call ping
        out r0, port_reg
        cpi r0, 15
        bnn sense0

        call rotate

sense1: call ping
        cpi r0, 15
        bn sense1

        br run
;******************************************************************************
ping:   push r1
       
        ldi r0, 0x01                   ; start a sonar reading
        out r0, sonar_control

poll1:  in r0, sonar_control           ; poll for data ready
        ani r0, 1
        bnz poll1

        in r1, sonar_range             ; get the sonar range

        ldi r0, 0x01
        out r0, sonar_control

poll2:  in r0, sonar_control
        ani r0, 1
        bnz poll2

        in r0, sonar_range
        add r0, r1
        rrc r0

        pop r1
        ret
;******************************************************************************
forwards:  
        push r0
        ldi r0, 60
        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r0, 0b00000101
        out r0, motor_control
        pop r0
        ret
;******************************************************************************
rotate: push r0
        ldi r0, 40
        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r0, 0b00001001
        out r0, motor_control
        pop r0
        ret
;******************************************************************************