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

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;******************************************************************************         
        .code

        ldi r0, 103
        out r0, uart_baud       ; set the baud rate to 9600

        ldi r0, 0b11111
        out r0, dir_reg         ; Set the first 5 bits of the i/o port to output

poll:   in r0, uart_ctrl
        ani r0, 1
        bz poll                 ; poll for full rx buffer

        in r0, uart_buffer      ; read the rx buffer
        out r0, port_reg        ; write the captured data to the i/o port

        br  poll                ; look for more data
;******************************************************************************