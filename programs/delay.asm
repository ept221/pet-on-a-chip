;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05
        .define counter_val, 0x08

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

        .define gpu_isr_vector, 0x0014
        .define top_isr_vector, 0x001E
;******************************************************************************        
        .code
                
        ldi r14, 0xff                   ; set stack pointer
        ldi r15, 0x00
        
        ldi r0, 128                     ; center the servo
        out r0, servo

        ldi r0, 1                       ; set gpio[0] to output
        out r0, dir_reg

        ldi r0, 0x18
        out r0, prescaler_h             ; set MSPs of prescaler

        ldi r0, 0x6A
        out r0, prescaler_l             ; set LSBs of prescaler

        ssr 8                           ; enable all interrupts

        br main
;******************************************************************************
        .org top_isr_vector
isr:    adi r0, -1                      ; decrement the delay counter 
        ssr 8
        rnz                             ; If delay counter not zero, return                     

        ldi r1, 0                       ; else, stop the counter and interrupts
        out r1, count_ctrl              
        ret
;******************************************************************************
main:   in r0, port_reg
        xoi r0, 1
        out r0, port_reg

        ldi r0, 10
        call delay
        br main
;******************************************************************************
        ; r0 holds the delay in tenths of a second
delay:  push r0
        push r1

        ldi r1, 0x00
        out r1, counter_val             ; clear the counter 

        ldi r1, 0b00010010
        out r1, count_ctrl              ; set pwm mode and enable top interrupt

loop:   cpi r0, 0
        bnz loop                        ; wait for delay to be over

        pop r1
        pop r0
        ret
;******************************************************************************