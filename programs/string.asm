;*************************************************
        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
;*************************************************      
        .code

        ldi r0, 0b00001100
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]

stable: in r0, gpu_ctrl_reg
        ani r0, 0x80
        bz stable

        ldi r0, text[l]
        ldi r1, text[h]

loop:   lri r4, p0
        cpi r4, 0
        bz end
        sri r4, p2
        br loop

end:    hlt
;*************************************************
        .data

text:   .string "GitHub repo at: https://github.com/ept221/pet-on-a-chip"
;*************************************************