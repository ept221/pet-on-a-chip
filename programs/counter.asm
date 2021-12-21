;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define top_isr_vec_reg_l, 0x16
        .define top_isr_vec_reg_h, 0x17
;******************************************************************************         
        .code
                
        ldi r14, 0xff                   ; set stack pointer

        ldi r0, isr[l]                  ; setup the top isr vector
        out r0, top_isr_vec_reg_l
        ldi r0, isr[h]
        out r0, top_isr_vec_reg_h

        ldi r0, 0b00011000
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]

        ldi r0, 0xff
        out r0, dir_reg                 ; set all pins to output

        ldi r0, 36
        out r0, prescaler_l             ; set LSBs of prescaler

        ldi r0, 244
        out r0, prescaler_h             ; set MSPs of prescaler

        ldi r0, 0b00010010
        out r0, count_ctrl              ; set pwm mode, set top interrupt

        ldi r5, 0

        ssr 8                           ; enable interrupts
loop:   br loop                         ; loop and wait for interrupt
;******************************************************************************
isr:    out r5, port_reg
        mov r12, r5
        call numToStr
        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]
        adi r5, 1
exit:   ssr 8                           ; enable interrupts
        ret
;******************************************************************************
numToStr:
        mov r13, r12
        srl r13
        srl r13
        srl r13
        srl r13
        cpi r13, 0x09
        bn alpha1
        adi r13, 48
        br print1
alpha1: adi r13, 55
print1: sri r13, p2
        ani r12, 0x0f
        cpi r12, 0x09
        bn alpha2
        adi r12, 48
        br print2
alpha2: adi r12, 55
print2: sri r12, p2
        ret
;******************************************************************************