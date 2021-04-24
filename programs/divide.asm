				.code

;******************************************************************************
; r0 holds the dividend
; r1 holds the divisor
; r2 holds the quotient
; r3 holds the remainder

divide:			push r0
				push r4

				csr	0b1110			; clear the carry

				ldi r3, 0			; initilize the remander to zero
				ldi r4, 8			; initilize the counter

				cpi r4, 0
				bz divide_end		; finish if we've shifted all 8 times

				rlc r0				; shift the dividend left and bring in the msb of the remainder
				rlc r3				; shift the remainder left and bring in the msb of the dividend

divide_end:		pop r4
				pop r0
				ret
