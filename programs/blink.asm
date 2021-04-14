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

        ldi r0, 1
        out r0, dir_reg                 ; set pin 1 to output

        ldi r0, 36
        out r0, prescaler_l             ; set LSBs of prescaler

        ldi r0, 244
        out r0, prescaler_h             ; set MSPs of prescaler

        ldi r0, 0b00010010
        out r0, count_ctrl              ; set pwm mode, set top interrupt

        csr 0
        ssr 8                           ; enable interrupts
loop:   br -1                           ; loop and wait for interrupt
        hlt

        .org top_isr_vector
isr:    in r0, port_reg                 ; read pin register
        xoi r0, 1                       ; toggle the led bit
        out r0, port_reg                ; write to the port register
        csr 0
        ssr 8                           ; enable interrupts
        ret
;******************************************************************************