mnm_r_i = {
	'LDI': "DDDDIIIIIIII0001",
	'ANI': "DDDDIIIIIIII0010",
	'ORI': "DDDDIIIIIIII0011",
	'XOI': "DDDDIIIIIIII0100",
	'ADI': "DDDDIIIIIIII0101",
	'ACI': "DDDDIIIIIIII0110",
	'CPI': "DDDDIIIIIIII0111",  
}

mnm_r_io = {
	'IN':  "DDDDIIIIIIII1000",
	'OUT': "SSSSIIIIIIII1001",
}

mnm_r_r = {
	'MOV': "DDDDSSSS00011010",
	'AND': "DDDDSSSS00101010",
	'OR':  "DDDDSSSS00111010",
	'XOR': "DDDDSSSS01001010",
	'ADD': "DDDDSSSS01011010",
	'ADC': "DDDDSSSS01101010",
	'CMP': "DDDDSSSS01111010",
	'SUB': "DDDDSSSS10001010",
	'SBB': "DDDDSSSS10011010",
}

mnm_r_p = {
	'SRI': "SSSSPPP011001010",
	'SRD': "SSSSPPP011011010",
	'LRI': "SSSSPPP011101010",
	'LRD': "SSSSPPP011111010",
}

mnm_r_p_k = {
	'STR': "SSSSPPPKKKKK1011",
	'LDR': "DDDDPPPKKKKK1100",
}

mnm_p_i = {
	'API': "IIIIPPPIIIII1101",
}

mnm_br = {
	'BR':  "000AAAAAAAAA1110",
	'BC':  "001AAAAAAAAA1110",
	'BNC': "010AAAAAAAAA1110",
	'BZ':  "011AAAAAAAAA1110",
	'BNZ': "100AAAAAAAAA1110",
	'BN':  "101AAAAAAAAA1110",
	'BNN': "110AAAAAAAAA1110",
}

mnm_r = {
	'SLL': "DDDD000010101111",
	'SRL': "DDDD000010111111",
	'SRA': "DDDD000011001111",
	'RLC': "DDDD000011011111",
	'RRC': "DDDD000011101111",
	'NOT': "DDDD000011111111",
	'POP': "DDDD111000100000",
	'PUSH': "SSSS111011011010",
}

mnm_p = {
	'JMPI': "0000PPP000011111",
	'JCI':  "0010PPP000011111",
	'JNCI': "0100PPP000011111",
	'JZI':  "0110PPP000011111",
	'JNZI': "1000PPP000011111",
	'JNI':  "1010PPP000011111",
	'JNNI': "1100PPP000011111",
}

mnm_a = {
	'JMP':  "0000111000101111",
	'JC':   "0010111000101111",
	'JNC':  "0100111000101111",
	'JZ':   "0110111000101111",
	'JNZ':  "1000111000101111",
	'JN':   "1010111000101111",
	'JNN':  "1100111000101111",
	'CALL': "0000111000111111",
	'CC':   "0010111000111111",
	'CNC':  "0100111000111111",
	'CZ':   "0110111000111111",
	'CNZ':  "1000111000111111",
	'CN':   "1010111000111111",
	'CNN':  "1100111000111111",
}

mnm_n = {
	'RET': "0000111001001111",
	'RC':  "0010111001001111",
	'RNC': "0100111001001111",
	'RZ':  "0110111001001111",
	'RNZ': "1000111001001111",
	'RN':  "1010111001001111",
	'RNN': "1100111001001111",
	'PUS': "0000111001011111",
	'POS': "0000111001101111",
	'NOP': "0000000000000000",
	'HLT': "1111111111111111",
}

mnm_m = {
	'SSR': "0000MMMM01111111",
	'CSR': "0000MMMM10001111",
}

mnm_p_p = {
	'MVP': "PPP0PPP010011111",
}

drct_0 = {
	'.CODE',
	'.DATA',
}

drct_1 = {
	'.ORG',
}

drct_2 = {
	'.DEFINE',
}

drct_m = {
	'.DB',
}

drct_s = {
	'.STRING',
}

registers = {
	'R0',
	'R1',
	'R2',
	'R3',
	'R4',
	'R5',
	'R6',
	'R7',
	'R8',
	'R9',
	'R10',
	'R11',
	'R12',
	'R13',
	'R14',
	'R15',
}

pairs = {
	'P0',
	'P2',
	'P4',
	'P6',
	'P8',
	'P10',
	'P12',
	'P14'
}

reserved_mnm_r_i = {key for key in mnm_r_i}
reserved_mnm_io = {key for key in mnm_r_io}
reserved_mnm_r_r = {key for key in mnm_r_r}
reserved_mnm_r_p = {key for key in mnm_r_p}
reserved_mnm_r_p_k = {key for key in mnm_r_p_k}
reserved_mnm_p_i = {key for key in mnm_p_i}
reserved_mnm_br = {key for key in mnm_br}
reserved_mnm_r = {key for key in mnm_r}
reserved_mnm_p = {key for key in mnm_p}
reserved_mnm_a = {key for key in mnm_a}
reserved_mnm_n = {key for key in mnm_n}
reserved_mnm_m = {key for key in mnm_m}
reserved_mnm_p_p = {key for key in mnm_p_p}

reserved = (reserved_mnm_r_i | reserved_mnm_io | reserved_mnm_r_r | reserved_mnm_r_p |
			reserved_mnm_r_p_k | reserved_mnm_p_i | reserved_mnm_br | reserved_mnm_r |
			reserved_mnm_p | reserved_mnm_a | reserved_mnm_n | reserved_mnm_m | 
			reserved_mnm_p_p | drct_0 | drct_0 | drct_1 | drct_2 | drct_m | drct_s |
			registers | pairs)