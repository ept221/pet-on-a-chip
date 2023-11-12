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

        .define top_isr_vec_reg_l, 0x17
        .define top_isr_vec_reg_h, 0x18

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;******************************************************************************
        .code

        ldi r14, 0xff                   ; setup stack pointer
        ldi r15, 0x00

        ldi r0, isr[l]                  ; setup the top isr vector
        out r0, top_isr_vec_reg_l
        ldi r0, isr[h]
        out r0, top_isr_vec_reg_h

        ldi r0, 128                     ; setup servo
        out r0, servo

        ldi r0, 0xff                    ; enable motor
        out r0, motor_enable

        ldi r0, 0b00011111              ; set the led gpio pins to output
        out r0, dir_reg
        out r0, port_reg                ; turn on all the leds

        ldi r0, 0x18
        out r0, prescaler_h             ; set MSPs of prescaler

        ldi r0, 0x6A
        out r0, prescaler_l             ; set LSBs of prescaler

        ssr 8                           ; enable all interrupts

        br main
;******************************************************************************
isr:    adi r0, -1                      ; decrement the delay counter 
        ssr 8
        rnz                             ; If delay counter not zero, return                     

        ldi r1, 0                       ; else, stop the counter and interrupts
        out r1, count_ctrl              
        ret
;******************************************************************************
main:   in r0, pin_reg                  ; wait for button to be pressed
        ani r0, 0b00100000
        bnz main

loop:   ldi r0, 60                      ; move forwards
        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r0, 0b00000101
        out r0, motor_control

sense0: call ping
        out r0, port_reg                ; display lsbs of the range on the leds
        cpi r0, 15
        bnn sense0

        ldi r0, 0                       ; stop
        out r0, motor_pwm0
        out r0, motor_pwm1
        ldi r0, 0b00001111
        out r0, motor_control

        ldi r0, 0                       ; look to the right
        out r0, servo
        
        ldi r0, 8                       ; wait for 0.8 seconds
        call delay

        call ping
        out r0, port_reg                ; display lsbs of the range on the leds
        mov r1, r0                      ; but the right range into r1

        ldi r0, 255                     ; look to the left
        out r0, servo

        ldi r0, 8
        call delay                      ; wait for 0.8 seconds

        call ping
        mov r2, r0
        out r2, port_reg                ; display lsbs of the range on the leds

        ldi r0, 128
        out r0, servo
        ldi r0, 8
        call delay

        cmp r2, r1
        bn right

left:   ldi r0, 0b00001001
        br rotate

right:  ldi r0, 0b00000110

rotate: out r0, motor_control
        ldi r0, 40
        out r0, motor_pwm0
        out r0, motor_pwm1

        ldi r0, 6
        call delay

        ldi r0, 0b00000101              ; move forwards 
        out r0, motor_control

        br loop
;******************************************************************************
; r0 will hold the result
ping:   push r1
       
        ldi r0, 0x01                    ; start a sonar reading
        out r0, sonar_control

poll1:  in r0, sonar_control            ; poll for data ready
        ani r0, 1
        bnz poll1

        in r1, sonar_range              ; get the sonar range

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
; r0 holds the delay in tenths of a second
delay:  push r0
        push r1

        ldi r1, 0x00
        out r1, counter_val             ; clear the counter 

        ldi r1, 0b00010010
        out r1, count_ctrl              ; set pwm mode and enable top interrupt

loop2:  cpi r0, 0
        bnz loop2                       ; wait for delay to be over

        pop r1
        pop r0
        ret
;******************************************************************************