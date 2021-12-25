;******************************************************************************
        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C
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