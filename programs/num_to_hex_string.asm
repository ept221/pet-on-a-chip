;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0014
        .define top_isr_vector, 0x001E
;******************************************************************************         
        .code
                
        ldi r14, 0xff                   ; set stack pointer

        ldi r0, 0b00011000
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]
;******************************************************************************
main:   ldi r0, 0xff
        ldi r1, 0x3d

        ldi r4, 1
        ldi r5, 0

        add r0, r4
        adc r1, r5

        mov r12, r1
        call numToStr

        mov r12, r0
        call numToStr

        hlt
;******************************************************************************
; Prints the value in r12 to the screen, in hex.
; It expects the gpu pointer to be in p2.
numToStr:
        mov r13, r12
        srl r13
        srl r13
        srl r13
        srl r13
        cpi r13, 0x09
        bc alpha1
        adi r13, 48
        br print1
alpha1: adi r13, 55
print1: sri r13, p2
        ani r12, 0x0f
        cpi r12, 0x09
        bc alpha2
        adi r12, 48
        br print2
alpha2: adi r12, 55
print2: sri r12, p2
        ret
;******************************************************************************