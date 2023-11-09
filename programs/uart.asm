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

        .define top_isr_vec_reg_l, 0x15
        .define top_isr_vec_reg_h, 0x16

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;******************************************************************************         
        .code

        ldi r0, 8
        out r0, uart_baud        ; set the baud rate to 115200

start:  ldi r2, text[l]
        ldi r3, text[h]

loop:   in r1, uart_ctrl
        ani r1, 2
        bz loop                  ; poll for empty buffer

        lri r0, p2               ; check for end of string
        cpi r0, 0
        bz start

        out r0, uart_buffer      ; print the char
        br loop
;******************************************************************************
        .data
text:   .string "GitHub repo at: https://github.com/ept221/pet-on-a-chip\n"