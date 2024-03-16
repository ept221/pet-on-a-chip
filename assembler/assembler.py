##############################################################################################################
import re
import sys
import table
import argparse
import preferences
##############################################################################################################
# Support Classes
class Symbol:

    def __init__(self):
        self.labelDefs = {}
        self.expr = []
        self.defs = {}

class Code:

    def __init__(self):
        self.code_data = []
        self.code_address = 0
        self.data_data = []
        self.data_address = 0
        self.code_label = ""
        self.data_label = ""

        self.codeSegment = False
        self.dataSegment = False
        self.segment = ""

    def write_code(self, line, data, code_string, status):

        if(self.code_address > preferences.i_ram_len):
            error("Cannot write past " + format(preferences.i_ram_len, '04X') + ". Out of program memory!",line)
            sys.exit(2)

        self.code_data.append([line, str(line[0][0]), format(self.code_address,'04X'),self.code_label,data, code_string, status])
        self.code_label = ""
        self.code_address += 1

    def write_data(self, line, data):

        if(self.data_address > preferences.d_ram_len):
            error("Cannot write past 0x" + format(preferences.d_ram_len, '02X') + ". Out of data memory!",line)
            sys.exit(2)

        self.data_data.append([line, str(line[0][0]), format(self.data_address,'04X'),self.data_label,data])
        self.data_label = ""
        self.data_address += 1
##############################################################################################################
# File reading functions
def read(name):
    # This function reads in lines from the asm file
    # It processes them and puts them into the form:
    # [[Line_number, Program_Counter] [body] [comment]]
    # Line_number corrisponds to the line on the 
    # source code. the Program_Counter is incremented
    # every time there is a non-empty line. Note that two
    # consecutive PC locations do NOT nessisarily corrispond
    # to two consecutive address locations. The comment feild
    # is initially left blank, but is used later by the lexer

    # [[Line_number, Program_Counter] [body] 'comment']
    
    try:
        file = open(name, 'r')
    except FileNotFoundError:
        print("File not found!")
        sys.exit(2)
    lines = []
    lineNumber = 0
    pc = 0
    
    for lineNumber, line in enumerate(file, start=1):
        line = line.strip()
        if(line):
            block = []
            block.append([lineNumber, pc])
            words = my_split(line)
            words = list(filter(None, words))
            block.append(words)
            block.append("")                     # A place holder for comments
            lines.append(block)
            pc += 1
    file.close()
    return lines
##############################################################################################################
# A line splitting function for the lexer
def my_split(line):
    words = []
    char_capture = False
    word = ""
    while(len(line) != 0):
        char = line[0]
        line = line[1:]
        if(char_capture):
            if(char == "\'"):
                if(word and word[-1] != "\\"):
                    word += char
                    words.append(word)
                    word = ""
                    char_capture = False
                else:
                    word += char
            else:
                word += char
        elif(char == "\'"):
            word += char
            char_capture = True
        elif(char == "[" and len(line) >= 2 and (line[:2].upper() == "H]" or line[:2].upper() == "L]")):
            words.append(word)
            word = ""
            word += char
            word += line[:2]
            line = line[2:]
        elif(char in [" ", "+","-",";",",","\""]):
            if(word):
                words.append(word)
            words.append(char)
            word = ""
        else:
            word += char
    if(word):
        words.append(word)
    return words
##############################################################################################################
def lexer(lines):
    codeLines = []
    tokens = []

    for line in lines:

        tl = []
        block = [line[0],[],""]

        commentCapture = False
        stringCapture = False

        for word in line[1]:
            ################################################################
            if(commentCapture):
                block[-1] += word
            ################################################################
            elif(stringCapture):
                block[1].append(word)
                slash_count = 0
                if(word == "\""):
                    for x in reversed(tl[-1][1]):
                        if x == "\\":
                            slash_count += 1
                        else:
                            break
                    if(slash_count % 2 == 0):
                        tl.append(["<quote>", word])
                        stringCapture = False
                    else:
                        tl.append(["<string_seg>", word])
                else:
                    tl.append(["<string_seg>", word])
            ################################################################
            else:
                if(word == ";"):
                    block[-1] += word          
                    commentCapture = True
                elif(word == "\""):
                    block[1].append(word)
                    tl.append(["<quote>", word])
                    stringCapture = True
                else:
                    block[1].append(word)
                    word = word.strip()
                    upper_word = word.upper()
                    if upper_word == "\"":
                        tl.append(["<quote>", upper_word])
                        stringCapture = True
                    elif(re.match(r'^\s*$',upper_word)):
                        pass
                    elif upper_word in table.mnm_r_i:
                        tl.append(["<mnm_r_i>", upper_word])
                    elif upper_word in table.mnm_r_io:
                        tl.append(["<mnm_r_io>", upper_word])
                    elif upper_word in table.mnm_r_r:
                        tl.append(["<mnm_r_r>", upper_word])
                    elif upper_word in table.mnm_r_p:
                        tl.append(["<mnm_r_p>", upper_word])
                    elif upper_word in table.mnm_r_p_k:
                        tl.append(["<mnm_r_p_k>", upper_word])
                    elif upper_word in table.mnm_p_i:
                        tl.append(["<mnm_p_i>", upper_word])
                    elif upper_word in table.mnm_br:
                        tl.append(["<mnm_br>", upper_word])
                    elif upper_word in table.mnm_r:
                        tl.append(["<mnm_r>", upper_word])
                    elif upper_word in table.mnm_p:
                        tl.append(["<mnm_p>", upper_word])
                    elif upper_word in table.mnm_a:
                        tl.append(["<mnm_a>", upper_word])
                    elif upper_word in table.mnm_n:
                        tl.append(["<mnm_n>", upper_word])
                    elif upper_word in table.mnm_m:
                        tl.append(["<mnm_m>", upper_word])
                    elif upper_word in table.mnm_p_p:
                        tl.append(["<mnm_p_p>", upper_word])
                    elif upper_word in table.drct_0:
                        tl.append(["<drct_0>", upper_word])
                    elif upper_word in table.drct_1:
                        tl.append(["<drct_1>", upper_word])
                    elif upper_word in table.drct_2:
                        tl.append(["<drct_2>", upper_word])
                    elif upper_word in table.drct_m:
                        tl.append(["<drct_m>", upper_word])
                    elif upper_word in table.drct_s:
                        tl.append(["<drct_s>", upper_word])
                    elif upper_word == "[L]" or upper_word == "[H]":
                        tl.append(["<selector>", upper_word])
                    elif upper_word == ",":
                        tl.append(["<comma>", upper_word])
                    elif upper_word == "+":
                        tl.append(["<plus>", upper_word])
                    elif upper_word == "-":
                        tl.append(["<minus>", upper_word])
                    elif upper_word in table.registers:
                        tl.append(["<reg>", upper_word])
                    elif upper_word in table.pairs:
                        tl.append(["<pair>", upper_word])
                    elif(re.match(r'^\'([^\'\\]|\\.)\'', word)):
                        tl.append(["<char>", word])
                    elif re.match(r'^.+:$',upper_word):
                        tl.append(["<lbl_def>", upper_word])
                    elif(re.match(r'^(0X)[0-9A-F]+$', upper_word)):
                        tl.append(["<hex_num>", upper_word])
                    elif(re.match(r'^[0-9]+$', upper_word)):
                        tl.append(["<dec_num>", upper_word])
                    elif(re.match(r'^(0B)[0-1]+$', upper_word)):
                        tl.append(["<bin_num>", upper_word]) 
                    elif(re.match(r'^[A-Z_0-9]+$', upper_word)):
                        tl.append(["<symbol>", upper_word])
                    elif upper_word == "$":
                        tl.append(["<lc>", upper_word])
                    else:
                        tl.append(["<idk_man>", upper_word])
                        error("Unknown token: " + upper_word, line)
                        return [0 , 0]
            ################################################################            
        if(block[1]):
            tokens.append(tl)
            codeLines.append(block)

    return [codeLines, tokens]
##############################################################################################################
def error(message, line):
    print("Error at line " + str(line[0][0]) + ": " + message)
##############################################################################################################
# Parses an expression if it exists. Returns an expr if found, returns 0 if not, returns error if bad expr.
def parse_expr(tokens, symbols, code, line):
    data = ["<expr>"]
    er = ["<error>"]
    if not tokens:                                              # If there are no tokens
        return 0                                                    # Then we couldn't find an expresion
    ##################################################
    while(tokens):
        if(tokens[0][0] in {"<plus>", "<minus>"}):              # If we have an operator
            data.append(tokens.pop(0))                              # Then get the operator
        elif(len(data) > 1):                                    # Else if we currently have a valid expression captured, and the next token we just looked at wasn't an operator
            return data                                             # Then return the valid expression
        if(len(data) > 1 and (not tokens)):                     # If we just saw an operator but we have more tokens
            error("Expression missing number/symbol!",line)         # Then return an error
            return er
        if(tokens[0][0] == "<char>"):
            try:
                bytes(tokens[0][1],"utf-8").decode("unicode_escape")
            except:
                error("Unsupported escape sequence for char!",line)
                return er
        if(tokens[0][0] not in {"<hex_num>", "<dec_num>", "<bin_num>", "<symbol>", "<lc>", "<char>"}): # Either we haven't seen anything at all, or the last token we saw was an operator. If the current token isn't a number/symbol/lc
            if(tokens[0][0] in {"<plus>", "<minus>"}):
                error("Expression has extra operator!",line)
                return er
            if(tokens[0][0] == "<selector>"):
                error("Expression has bad selector!",line)
                return er
            if(len(data) > 1):                                  # If the last token we saw was an operator, but the current token isn't legal
                error("Expression has bad identifier!",line)        # Then return an error
                return er
            else:                                               # If we haven't seen anything at all, and the current token isn't a legal start of one
                return 0                                            # The we couldn't find an expresion 
        data.append(tokens.pop(0))                              # Get the number
        if(tokens and tokens[0][0] == "<selector>"):            # Capture a selector if it exists
            data.append(tokens.pop(0))

    return data
##############################################################################################################
def expr_to_str(expr):
    expr_str = expr[0][1]
    if(expr[0][0] != "<plus>" and expr[0][0] != "<minus>" and len(expr) != 1 and expr[1][0] != "<selector>"):
        expr_str = expr_str + " "

    for i, x in enumerate(expr[1:-1], start = 1):
        expr_str = expr_str + x[1]
        if(expr[i+1][0] != "<selector>"):
            expr_str += " "
    if(len(expr) != 1):
        expr_str = expr_str + expr[-1][1]
    return expr_str
##############################################################################################################
def evaluate(expr, symbols, address, mode):
    ##################################################
    def modify(val, selector):
        if(selector == "[L]"):
            return int(format(val, '016b')[8:16],base=2)
        elif(selector == "[H]"):
            return int(format(val, '016b')[0:8],base=2)
        else:
            return val
    ##################################################

    sign, pop, numpos, result = 1, 2, -1, 0
    while(expr):
        ##################################################
        if(len(expr) >= 3 and expr[-1][0] == "<selector>"):
            pop = 3
            numpos = -2
            selector = expr[-1][1]
            if(expr[-3][0] == "<plus>"):
                sign = 1
            else:
                sign = -1
        elif(len(expr) == 2 and expr[-1][0] == "<selector>"):
            pop = 2
            numpos = -2
            selector = expr[-1][1]
            sign = 1
        elif(len(expr) >= 2):
            pop = 2
            numpos = -1
            selector = ""
            if(expr[-2][0] == "<plus>"):
                sign = 1
            else:
                sign = -1
        else:
            pop = 1
            numpos = -1
            selector = ""
            sign = 1
        ##################################################
        if(expr[numpos][0] == "<hex_num>"):
            result += sign*modify(int(expr[numpos][1], base=16),selector)
            expr = expr[:-pop]
        elif(expr[numpos][0] == "<dec_num>"):
            result += sign*modify(int(expr[numpos][1], base=10),selector)
            expr = expr[:-pop]
        elif(expr[numpos][0] == "<bin_num>"):
            result += sign*modify(int(expr[numpos][1], base=2),selector)
            expr = expr[:-pop]
        elif(expr[-1][0] == "<char>"):
            result += sign*ord(bytes(expr[-1][1][1:-1],"utf-8").decode("unicode_escape"))
            expr = expr[:-pop]
        elif(expr[numpos][0] == "<lc>"):
            result += sign*modify((address),selector)
            expr = expr[:-pop]
        elif(expr[numpos][1] in symbols.labelDefs):
            if(mode == "diff"):
                result += sign*(modify(int(symbols.labelDefs[expr[numpos][1]],base=16),selector)-address)
            else:
                result += sign*modify(int(symbols.labelDefs[expr[numpos][1]],base=16),selector)
            expr = expr[:-pop]
        elif(expr[numpos][1] in symbols.defs):
            result += sign*modify(int(symbols.defs[expr[numpos][1]],base=16),selector)
            expr = expr[:-pop]
        else:
            expr += [["<plus>", "+"],["<hex_num>",hex(result)]]
            return expr
        ##################################################
    return [result]
##############################################################################################################
def parse_lbl_def(tokens, symbols, code, line):
    er = ["<error>"]
    if not tokens:
        return 0
    ##################################################
    if(tokens[0][0] == "<lbl_def>"):
        lbl = tokens[0][1]
        if(not code.segment):
            error("Label cannot be defined outside memory segment!", line)
            return er
        if((code.segment == "code" and code.code_label) or (code.segment == "data" and code.data_label)):
            error("Label cannot come after another label, before the first one is bound!",line)
            return er
        elif lbl[:-1] in symbols.labelDefs:
            error("Label already in use!",line)
            return er
        elif lbl[:-1] in table.reserved:
            error("Label cannot be keyword!",line)
            return er
        elif re.match(r'^(0X)[0-9A-F]+$',lbl[:-1] or
             re.match(r'^[0-9]+$',lbl[:-1]) or
             re.match(r'^(0B)[0-1]+$',lbl[:-1])):
            error("Label cannot be number!",line)
            return er
        elif lbl[:-1] in (symbols.defs):
            error("Label conflicts with previous symbol definition",line)
            return er
        else:
            if(code.segment == "code"):
                symbols.labelDefs[lbl[:-1]] = '{0:0{1}X}'.format(code.code_address,4)
                code.code_label = lbl
            else:
                symbols.labelDefs[lbl[:-1]] = '{0:0{1}X}'.format(code.data_address,4)
                code.data_label = lbl
        return tokens.pop(0)
    else:
        return 0
##############################################################################################################
def setCodeSegment(arg, symbols, code, line):
    if(code.codeSegment or code.segment == "code"):
        error("Code segment already defined!",line)
        return 0
    else:
        code.codeSegment = True
        code.segment = "code"
        return 1
##############################################################################################################
def setDataSegment(arg, symbols, code, line):
    if(code.dataSegment or code.segment == "data"):
        error("Data segment already defined!",line)
        return 0
    else:
        code.dataSegment = True
        code.segment = "data"
        return 1
##############################################################################################################
def org(arg, symbols, code, line):
    address = 0
    if(not code.segment):
        error("Directive must be within code or data segment!",line)
        return 0
    elif(code.segment == "code"):
        address = code.code_address
    else:
        address = code.data_address

    if(arg < 0):
        error("Expression must be positive!",line)
        return 0
    elif(arg < address):
        error("Cannot move origin backwards!",line)
        return 0
    else:
        if(code.segment == "code"):
            if(arg > preferences.i_ram_len):
                error("Cannot set code origin past " + format(preferences.i_ram_len, '04X') + "!",line)
                return 0
            code.code_address = arg
            if(code.code_label):
                symbols.labelDefs[code.code_label[:-1]] = '{0:0{1}X}'.format(address,4)
        else:
            if(arg > preferences.d_ram_len):
                error("Cannot set data origin past " + format(preferences.d_ram_len, '02X') + "!",line)
                return 0
            code.data_address = arg
            if(code.data_label):
                symbols.labelDefs[code.data_label[:-1]] = '{0:0{1}X}'.format(address,4)
    return 1
##############################################################################################################
def define(args, symbols, code, line):
    if(args[0] in symbols.labelDefs):
        error("Symbol definition conflicts with label def!",line)
        return 0
    if(args[0] in symbols.defs):
        error("Symbol definition conflicts with previous definition!",line)
        return 0
    symbols.defs[args[0]] = hex(args[1])
    return 1
##############################################################################################################
def db(args, symbols, code, line):
    if(code.segment != "data"):
        error("Directive must be within data segment!",line)
        return 0

    for arg in args:
        if(arg < -128 or arg > 255):
            error("Argument must be >= -128 and <= 255",line)
            return 0
        if(arg < 0):
            arg = 255 - abs(arg) + 1

        code.write_data(line, format(arg, '02X'))

    return 1

def ds(arg, symbols, code, line):
    if(code.segment != "data"):
        error("Directive must be within data segment!",line)
        return 0

    if(arg <= 0):
        error("Argument must be positive!",line)
        return 0
    if(arg + code.data_address > preferences.d_ram_len):
        error("Cannot define space past " + format(preferences.d_ram_len, '02X') + ".",line)
        return 0

    code.data_address += arg
    code.data_label = ""
    return 1

def store_string(arg, symbols, code, line):
    if(code.segment != "data"):
        error("Directive must be within data segment!",line)
        return 0

    for char in arg:
        if(int(ord(char)) > 128):
            error("Unsupported character in string: " + str(char),line)
            return 0

    new_str = bytes(arg,"utf-8").decode("unicode_escape")

    for char in new_str:
        code.write_data(line,format(ord(char),'02X'))
    code.write_data(line,format(0,'02X'))
    return 1

def store_open_string(arg, symbols, code, line):
    if(code.segment != "data"):
        error("Directive must be within data segment!",line)
        return 0

    for char in arg:
        if(int(ord(char)) > 128):
            error("Unsupported character in string: " + str(char),line)
            return 0

    new_str = bytes(arg,"utf-8").decode("unicode_escape")

    for char in new_str:
        code.write_data(line,format(ord(char),'02X'))
    return 1
##############################################################################################################
directives = {
    ".CODE": setCodeSegment,
    ".DATA": setDataSegment,
    ".ORG":  org,
    ".DEFINE": define,
    ".DB":  db,
    ".DS":  ds,
    ".STRING": store_string,
    ".OSTRING": store_open_string,
}
##############################################################################################################
def parse_drct(tokens, symbols, code, line):
    args = [tokens, symbols, code, line]
    data = ["<drct>"]
    er = ["<error>"]
    if not tokens:
        return 0
    ##################################################
    # [drct_0]
    if(tokens[0][0] == "<drct_0>"):
        drct_0 = tokens[0][1]
        data.append(tokens.pop(0))
        status = directives[drct_0](0,symbols,code,line)
        if not status:
            return er
        return data
    ##################################################
    # [drct_1]
    if(tokens[0][0] == "<drct_1>"):
        drct_1 = tokens[0][1]
        data.append(tokens.pop(0))
        address = 0
        if(code.segment == "code"):
            address = code.code_address
        elif(code.segment == "data"):
            address = code.data_address
        if(not tokens):
            error("Directive missing argument!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Directive has bad argument!", line)
            return er
        if(expr == er):
            return er
        val = evaluate(expr[1:],symbols,address,"abs")
        data.append(expr)
        if(len(val) == 1):
            status = directives[drct_1](val[0],symbols,code,line)
            if(not status):
                return er
        else:
            error("Directive relies upon unresolved symbol!",line)
        return data
    ##################################################
    # [drct_2]
    if(tokens[0][0] == "<drct_2>"):
        drct_2 = tokens[0][1]
        data.append(tokens.pop(0))
        address = 0
        if(code.segment == "code"):
            address = code.code_address
        elif(code.segment == "data"):
            address = code.data_address
        if(not tokens):
            error("Directive missing argument!",line)
            return er
        if(tokens[0][0] != "<symbol>"):
            error("Directive has bad argument!",line)
            return er
        symbol = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Directive missing comma and argument!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            if(tokens[0][0] not in {"<hex_num>","<dec_num>","<bin_num>","<symbol>"}):
                error("Directive has bad argument!",line)
                return er
            error("Directive missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Directive missing argument!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Directive has bad argument!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        val = evaluate(expr[1:],symbols,address,"abs")
        if(len(val) == 1):
            status = directives[drct_2]([symbol,val[0]],symbols,code,line)
            if(not status):
                return er
        else:
            error("Directive relies upon unresolved symbol!",line)
            return er
        return data
    ##################################################
    # [drct_m]
    if(tokens[0][0] == "<drct_m>"):
        drct_m = tokens[0][1]
        d_args = []
        data.append(tokens.pop(0))

        address = 0
        if(code.segment == "code"):
            address = code.code_address
        elif(code.segment == "data"):
            address = code.data_address

        if(not tokens):
            error("Directive missing argument!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Directive has bad argumet!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        val = evaluate(expr[1:],symbols,address,"abs")
        if(len(val) == 1):
            d_args.append(val[0])
        else:
            error("Directive relies upon unresolved symbol!",line)
            return er

        while(tokens):
            if(tokens[0][0] != "<comma>"):
                error("Missing comma!",line)
                return er
            data.append(tokens.pop(0))
            if(not tokens):
                error("Directive missing last argument or has extra comma!",line)
                return er
            expr = parse_expr(*args)
            if(not expr):
                error("Directive has bad argument!",line)
                return er
            data.append(expr)
            if(expr == error):
                return er
            data.append(expr)
            val = evaluate(expr[1:],symbols,address,"abs")
            if(len(val) == 1):
                d_args.append(val[0])
            else:
                error("Directive relies upon unresolved symbol!",line)
                return er
        status = directives[drct_m](d_args,symbols,code,line)
        if not status:
            return er
        return data
    ##################################################
    # [drct_s]
    if(tokens[0][0] == "<drct_s>"):
        drct_s = tokens[0][1]
        data.append(tokens.pop(0))
        string = ""
        if(not tokens):
            error("Directive missing argument!",line)
            return er
        if(tokens[0][0] != "<quote>"):
            error("Directive missing start quote!",line)
            return er
        data.append(tokens.pop(0))

        while(len(tokens) and tokens[0][0] != "<quote>"):
            string += tokens[0][1]
            data.append(tokens.pop(0))

        if(not tokens or tokens[0][0] != "<quote>"):
            error("Directive missing end quote!",line)
            return er
        data.append(tokens.pop(0))

        status = directives[drct_s](string,symbols,code,line)
        if not status:
            return er
        return data
##############################################################################################################
def parse_code(tokens, symbols, code, line):
    args = [tokens, symbols, code, line]
    data = ["<code>"]
    er = ["<error>"]
    if not tokens:
        return 0
    ##################################################
    # Check if inside the code segment
    if(tokens[0][0] in {"<mnm_r_i>","<mnm_r_r>","<mnm_r_p>","<mnm_r_p_k>",
                        "<mnm_p_i>","<mnm_br>","<mnm_r>","<mnm_p>","<mnm_a>",
                        "<mnm_n>","<mnm_p_p>"}
                        and not (code.segment == "code")):
        error("Instructions must be inside the code segment!", line)
        return ["<error>"]
    ##################################################
    # [mnm_r_i] or [mnm_r_io]
    if(tokens[0][0] == "<mnm_r_i>" or tokens[0][0] == "<mnm_r_io>"):
        inst_str = tokens[0][1]
        inst_tkn = tokens[0][0]
        arg_name = "data" if (inst_tkn == "<mnm_r_i>") else "port address"
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has bad register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and " + arg_name + "!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing " + arg_name + "!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Instruction has bad argument!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        ##################################################
        # Code Generation
        instruction = table.mnm_r_i[inst_str] if (inst_tkn == "<mnm_r_i>") else table.mnm_r_io[inst_str]
        instruction = format(int(reg1[1:]),'04b') + instruction[4:]
        code_string = inst_str + " " + reg1 + ", " + expr_to_str(expr[1:])
        val = evaluate(expr[1:],symbols,code.code_address,"abs")
        if(len(val) == 1):
            numb = val[0]
            if(numb < -128 or numb > 255):
                error("Argument must be >= -128 and <= 255",line)
                return er
            else:
                numb = numb if (numb >= 0) else (255 - abs(numb) + 1)
                instruction = instruction[0:4] + format(numb,'08b') + instruction[12:]
                code.write_code(line,instruction,code_string,0)
        else:
            code.write_code(line,instruction,code_string,[inst_tkn,val])

        return data
    ##################################################
    # [mnm_r_r]
    if(tokens[0][0] == "<mnm_r_r>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has a bad register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and register!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has bad register!",line)
            return er
        reg2 = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_r_r[inst_str]
        instruction = format(int(reg1[1:]),'04b') + format(int(reg2[1:]),'04b') + instruction[8:]
        code_string = inst_str + " " + reg1 + ", " + reg2
        code.write_code(line,instruction,code_string,0)
        return data
    ##################################################
    # [mnm_r_p]
    if(tokens[0][0] == "<mnm_r_p>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has bad register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and register!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has bad rp register!",line)
            return er
        reg2 = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_r_p[inst_str]
        instruction = format(int(reg1[1:]),'04b') + format(int(reg2[1:]),'04b') + instruction[8:]
        code_string = inst_str + " " + reg1 + ", " + reg2
        code.write_code(line,instruction,code_string,0)
        return data
    ##################################################
    # [mnm_r_p_k]
    if(tokens[0][0] == "<mnm_r_p_k>"):
        inst_str = tokens[0][1]
        inst_tkn = tokens[0][0]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has bad register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma rp register comma and offset!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register comma and offset!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has bad rp register!",line)
            return er
        reg2 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and offset!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing offset!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Instruction has bad offset!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        ##################################################
        # Code Generation
        instruction = table.mnm_r_p_k[inst_str]
        instruction = format(int(reg1[1:]),'04b') + format(int(reg2[1:]),'04b')[0:3] + instruction[7:]
        code_string = inst_str + " " + reg1 + ", " + reg2 + ", " + expr_to_str(expr[1:])
        val = evaluate(expr[1:],symbols,code.code_address,"abs")
        if(len(val) == 1):
            numb = val[0]
            if(numb < -16 or numb > 15):
                error("Offset must be >= -16 and <= 15.",line)
                return er
            else:
                numb = numb if (numb >= 0) else (31 - abs(numb) + 1)
                instruction = instruction[0:7] + format(numb,'05b') + instruction[12:]
                code.write_code(line,instruction,code_string,0)
        else:
            code.write_code(line,instruction,code_string,[inst_tkn,val])

        return data
    ##################################################
    # [mnm_p_i]
    if(tokens[0][0] == "<mnm_p_i>"):
        inst_str = tokens[0][1]
        inst_tkn = tokens[0][0]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has bad rp register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and data!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing data!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Instruction has bad data!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        ##################################################
        # Code Generation
        instruction = table.mnm_p_i[inst_str]
        instruction = instruction[:4] + format(int(reg1[1:]),'04b')[:-1] + instruction[7:]
        code_string = inst_str + " " + reg1 + ", " + expr_to_str(expr[1:])
        val = evaluate(expr[1:],symbols,code.code_address,"abs")
        if(len(val) == 1):
            numb = val[0]
            if(numb < -256 or numb > 511):
                error("Data must be >= -256 and <= 511.",line)
                return er
            else:
                numb = numb if (numb >= 0) else (511 - abs(numb) + 1)
                instruction = format(numb,'09b')[:4] + instruction[4:7] + format(numb,'09b')[4:] + instruction[12:]
                code.write_code(line,instruction,code_string,0)
        else:
            code.write_code(line,instruction,code_string,[inst_tkn,val])

        return data
    ##################################################
    # [mnm_r]
    if(tokens[0][0] == "<mnm_r>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing register!",line)
            return er
        if(tokens[0][0] != "<reg>"):
            error("Instruction has bad register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_r[inst_str]
        instruction = format(int(reg1[1:]),'04b') + instruction[4:]
        code_string = inst_str + " " + reg1
        code.write_code(line,instruction,code_string,0)
        return data
    ##################################################
    # [mnm_p]
    if(tokens[0][0] == "<mnm_p>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has bad rp register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_p[inst_str]
        instruction = instruction[:4] + format(int(reg1[1:]),'04b') + instruction[8:]
        code_string = inst_str + " " + reg1
        code.write_code(line,instruction,code_string,0)
        return data
    ##################################################
    # [mnm_a] or [mnm_m] or [mnm_br]
    if(tokens[0][0] == "<mnm_a>" or tokens[0][0] == "<mnm_br>") or tokens[0][0] == "<mnm_m>":
        inst_str = tokens[0][1]
        inst_tkn = tokens[0][0]
        arg_name = "address" if (inst_tkn == "<mnm_a>") else ("offset" if (inst_tkn == "<mnm_br>") else "mask")
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing " + arg_name + "!",line)
            return er
        expr = parse_expr(*args)
        if(not expr):
            error("Instruction has bad " + arg_name + "!",line)
            return er
        elif(expr == er):
            return er
        data.append(expr)
        ##################################################
        # Code Generation
        instruction = ""
        code_string = inst_str + " " + expr_to_str(expr[1:])
        if(inst_tkn == "<mnm_a>"):
            instruction = table.mnm_a[inst_str]
            address = ""
            code.write_code(line,instruction,code_string,0)
            val = evaluate(expr[1:],symbols,code.code_address,"abs")
            if(len(val) == 1):
                numb = val[0]
                if(numb < 0 or numb > preferences.i_ram_len):
                    error("Address must be >= 0 and <= "+str(preferences.i_ram_len)+".",line)
                    return er
                else:
                    address = format(numb,'016b')
                code.write_code(line,address,"",0)
            else:
                code.write_code(line,"AAAAAAAAAAAAAAAA","",[inst_tkn,val])
        elif(inst_tkn == "<mnm_br>"):
            instruction = table.mnm_br[inst_str]
            val = evaluate(expr[1:],symbols,code.code_address,"diff")
            if(len(val) == 1):
                numb = val[0]
                if(numb < -256 or numb > 255):
                    error("Offset must be >= -256 and <= 255.",line)
                    return er
                else:
                    if(numb + code.code_address < 0):
                        error("Instruction branches below address 0",line)
                        return er
                    if(numb + code.code_address > preferences.i_ram_len):
                        error("Instruction branches above address " + str(preferences.i_ram_len),line)
                        return er
                    numb = numb if (numb >= 0) else (511 - abs(numb) + 1)
                    instruction = instruction[:3] + format(numb,'09b') + instruction[12:]
                    code.write_code(line,instruction,code_string,0)
            else:
                code.write_code(line,instruction,code_string,[inst_tkn,val])
        else:
            instruction = table.mnm_m[inst_str]
            val = evaluate(expr[1:],symbols,code.code_address,"abs")
            if(len(val) == 1):
                numb = val[0]
                if(numb < 0 or numb > 16):
                    error("Mask must be >= 0 and <= 15.",line)
                    return er
                else:
                    instruction = instruction[0:4] + format(numb,'04b') + instruction[8:]
                code.write_code(line,instruction,code_string,0)
            else:
                code.write_code(line,instruction,code_string,[inst_tkn,val])

        return data
    ##################################################
    # [mnm_p_p]
    if(tokens[0][0] == "<mnm_p_p>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has a bad rp register!",line)
            return er
        reg1 = tokens[0][1]
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing comma and rp register!",line)
            return er
        if(tokens[0][0] != "<comma>"):
            error("Instruction missing comma!",line)
            return er
        data.append(tokens.pop(0))
        if(not tokens):
            error("Instruction missing rp register!",line)
            return er
        if(tokens[0][0] != "<pair>"):
            error("Instruction has bad rp register!",line)
            return er
        reg2 = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_p_p[inst_str]
        instruction = format(int(reg1[1:]),'04b') + format(int(reg2[1:]),'04b') + instruction[8:]
        code_string = inst_str + " " + reg1 + ", " + reg2
        code.write_code(line,instruction,code_string,0)
        return data
    ##################################################
    # [mnm_n]
    if(tokens[0][0] == "<mnm_n>"):
        inst_str = tokens[0][1]
        data.append(tokens.pop(0))
        ##################################################
        # Code Generation
        instruction = table.mnm_n[inst_str]
        code.write_code(line,instruction,inst_str,0)
        return data

    return 0
##############################################################################################################
# Grammar:
#
# <line> ::= <lbl_def> [<drct>] [<code>]
#          | <drct> [<code>]
#          | <code>
#
# <code> ::= <mnm_r_i> <reg> <comma> <expr>
#          | <mnm_r_io> <reg> <comma> <expr>
#          | <mnm_r_r> <reg> <comma> <reg>
#          | <mnm_r_p> <reg> <comma> <pair>
#          | <mnm_r_p_k> <reg> <comma> <pair> <comma> <expr>
#          | <mnm_p_i> <pair> <comma> <expr>
#          | <mnm_br> <expr>
#          | <mnm_r> <reg>
#          | <mnm_p> <pair>
#          | <mnm_a> <expr>
#          | <mnm_n>
#          | <mnm_m> <expr>
#          | <mnm_p_p> <pair> <comma> <pair>
#
# <expr> ::= [ (<plus> | <minus>) ] <numb> [ <selector> ] { (<plus> | <minus>) <numb> [ <selector> ]}
#
# <drct> ::= <drct_0> 
#          | <drct_1> <expr>
#          | <drct_2> <expr> <comma> <expr>
#          | <drct_m> <expr> { <comma>  <expr> }
#          | <drct_s> <quote> { <string_seg> } <quote>
#
# <numb> ::= <hex_num> | <dec_num> | <bin_num> | <symbol> | <lc> | <char>
#
##############################################################################################################
def parse_line(tokens, symbols, code, line):
    data = ["<line>"]
    er = ["<error>"]
    if(len(tokens) == 0):
        return 0
    ################################
    # [lbl_def]
    lbl_def = parse_lbl_def(tokens, symbols, code, line)
    if(lbl_def):
        if(lbl_def == er):
            return er
        data.append(lbl_def)
    ################################
    # [drct]
    drct = parse_drct(tokens, symbols, code, line)
    if(drct):
        if(drct == er):
            return er
        data.append(drct)
    ################################
    # [code]
    code = parse_code(tokens, symbols, code, line)
    if(code):
        if(code == er):
            return er
        data.append(code)
    ###############################
    # check to see that we have at
    # least one of lbl_def, drct,
    # or code
    if(len(data) < 2):
        tokens.pop(0)
        error("Bad Initial Identifier!",line)
        return er
    ###############################
    # check to see if we have any
    # tokens left
    if(len(tokens)):   
        error("Bad Final Identifier(s)!",line)
        return er
    ###############################
    # everything's good
    return data
##############################################################################################################
# Second pass
def second_pass(symbols, code):
    i = 0
    while i < len(code.code_data):
        code_line = code.code_data[i]
        line = code_line[0]
        if(code_line[-1]):
            mode = "diff" if(code_line[-1][0] == "<mnm_br>") else "abs"
            val = evaluate(code_line[-1][1],symbols,int(code_line[2],base=16),mode)
            if(len(val) == 1):
                numb = val[0]
                ##################################################
                # [mnm_r_i] or [mnm_r_io]
                if(code_line[-1][0] == "<mnm_r_i>" or code_line[-1][0] == "<mnm_r_io>"):
                    instruction = code_line[4]
                    arg_name = "Data" if (code_line[-1][0] == "<mnm_r_i>") else "Port address"
                    if(numb < -128 or numb > 255):
                        error("Argument must be >= -128 and <= 255",line)
                        return 0
                    else:
                        numb = numb if (numb >= 0) else (255 - abs(numb) + 1)
                        instruction = instruction[0:4] + format(numb,'08b') + instruction[12:]
                        code_line[4] = instruction
                        code_line[-1] = 0
                ##################################################
                # [mnm_r_p_k]
                elif(code_line[-1][0] == "<mnm_r_p_k>"):
                    instruction = code_line[4]
                    if(numb < -16 or numb > 15):
                        error(arg_name + " must be >= -16 and <= 15.",line)
                        return 0
                    else:
                        numb = numb if (numb >= 0) else (31 - abs(numb) + 1)
                        instruction = instruction[0:7] + format(numb,'05b') + instruction[12:]
                        code_line[4] = instruction
                        code_line[-1] = 0
                 ##################################################
                # [mnm_p_i]
                elif(code_line[-1][0] == "<mnm_p_i>"):
                    instruction = code_line[4]
                    if(numb < -256 or numb > 511):
                        error("Data must be >= -256 and <= 511.",line)
                        return 0
                    else:
                        numb = numb if (numb >= 0) else (511 - abs(numb) + 1)
                        instruction = format(numb,'09b')[:4] + instruction[4:7] + format(numb,'09b')[4:] + instruction[12:]
                        code_line[4] = instruction
                        code_line[-1] = 0
                ##################################################
                # [mnm_a]
                elif(code_line[-1][0] == "<mnm_a>"):
                    if(numb < 0 or numb > preferences.i_ram_len):
                        error("Address must be >= 0 and <= "+str(preferences.i_ram_len),line)
                        return 0
                    else:
                        code_line[4] = format(numb,'016b')
                        code_line[-1] = 0
                ##################################################
                # [mnm_br]
                elif(code_line[-1][0] == "<mnm_br>"):
                    instruction = code_line[4]
                    if(numb < -256 or numb > 255):
                        error("Offset must be >= -256 and <= 255.",line)
                        return 0
                    else:
                        if((numb + int(code_line[2], 16)) < 0):
                            error("Instruction branches below address 0", line)
                            return 0
                        if((numb + int(code_line[2], 16)) > preferences.i_ram_len):
                            error("Instruction branches above address " + str(preferences.i_ram_len),line)
                            return 0
                        numb = numb if (numb >= 0) else (511 - abs(numb) + 1)
                        instruction = instruction[:3] + format(numb,'09b') + instruction[12:]
                        code_line[4] = instruction
                        code_line[-1] = 0
                ##################################################
                # [mnm_m]
                elif(code_line[-1][0] == "<mnm_m>"):
                    instruction = code_line[4]
                    if(numb < 0 or numb > 16):
                        error("Mask must be >= 0 and <= 15",line)
                        return 0
                    else:
                        instruction = instruction[0:4] + format(numb,'04b') + instruction[8:]
            else:
                error("Expression relies on unresolved symbol!",line)
                return 0
        i += 1
    return 1
##############################################################################################################
def parse(lines, symbols, code):

    codeLines, tokenLines = lexer(lines)

    if(codeLines == 0):
        sys.exit(1)

    tree = []

    for tokens, line in zip(tokenLines, codeLines):
        parsedLine = parse_line(tokens, symbols, code, line)
        tree.append(parsedLine)
        if(parsedLine[0] == "<error>"):
            sys.exit(1)

    result = second_pass(symbols, code)
    if(not result):
        sys.exit(1)
##############################################################################################################
def genImage(code_list,out_file,length,hex_width):
    pair = []
    address = 0
    hex_width_str = "0"+str(hex_width)+"x"
    while(address < length):
        if(not pair):
            if(code_list):
                pair = code_list.pop(0)
                if(address == pair[0]):
                    print(format(pair[1], hex_width_str),file=out_file)
                    pair = []
                else:
                    print("0"*hex_width,file=out_file)
            else:
                print("0"*hex_width,file=out_file)
        else:
            if(address == pair[0]):
                    print(format(pair[1], hex_width_str),file=out_file)
                    pair = []
            else:
                print("0"*hex_width,file=out_file)
        address += 1
##############################################################################################################
def output(code, file_name, args):

    if(args.debug == True):

        code_file = open(file_name + ".instructions",'w') if file_name else sys.stdout
        data_file = open(file_name + ".data",'w') if file_name else sys.stdout

        print('{:<16}'.format("Line Number") + '{:<15}'.format("Address") + '{:<15}'.format("Label") + '{:<25}'.format("Code") + '{:<30}'.format("Source") + '{:<20}'.format("Comments"),file=code_file)
        for x in range(120):
            print("-",end="",file=code_file)
        print("",file=code_file)
        previous_line = -1
        for x in code.code_data:
            comment = ""
            if(previous_line != int(x[1])):
                comment = x[0][-1]
            print('{:<16}'.format(x[1]) + '{:<15}'.format("0x"+x[2]) + '{:<15}'.format(x[3]) + '{:<25}'.format("0b"+x[4]) + '{:<30}'.format(x[5]) + '{:<20}'.format(comment),file=code_file)
            previous_line = int(x[1])
        
        if(not file_name):
            print()

        print('{:<16}'.format("Line Number") + '{:<15}'.format("Address") + '{:<15}'.format("Label") + '{:<25}'.format("Data") + '{:<20}'.format("Comments"),file=data_file)
        for x in range(120):
            print("-",end="",file=data_file)
        print("",file=data_file)
        for x in code.data_data:
            comment = ""
            if(previous_line != int(x[1])):
                comment = x[0][-1]
            print('{:<16}'.format(x[1]) + '{:<15}'.format("0x"+x[2]) + '{:<15}'.format(x[3]) + '{:<25}'.format("0x"+x[4]) + '{:<20}'.format(comment),file=data_file)
            previous_line = int(x[1])
    else:
        instruction_list = []
        data_list = []
        for x in code.code_data:
            instruction_list.append([int(x[2],base=16),int(x[4],base=2)])
        for x in code.data_data:
            data_list.append([int(x[2],base=16),int(x[4],base=16)])

        code_image = open(file_name + "_instructions.hex",'w') if file_name else sys.stdout
        data_image = open(file_name + "_data.hex",'w') if file_name else sys.stdout

        genImage(instruction_list,code_image,preferences.i_ram_len,4)
        genImage(data_list,data_image,preferences.d_ram_len,2)

##############################################################################################################
# Main

try:
    if(preferences.i_ram_len < 0  or preferences.i_ram_len > 65535):
        print("Bad preferences! Instruction memory length must be >= 0 and <= 65535.")
        sys.exit(2)

except AttributeError:
    print("Bad preferences! The variable preferences.i_ram_len does not exist!")
    sys.exit(2)

try:
    if(preferences.d_ram_len < 0  or preferences.d_ram_len > 65535):
        print("Bad preferences! Data memory length must be >= 0 and <= 65535.")
        sys.exit(2)

except AttributeError:
    print("Bad preferences! The variable preferences.d_ram_len does not exist!")
    sys.exit(2)

code = Code()
symbols = Symbol()

description = 'An assembler for tinySoC'
p = argparse.ArgumentParser(description = description)
p.add_argument("source", help="source file")
p.add_argument("-o", "--out", help="output file name (stdout, if not specified)")
p.add_argument("-d", "--debug", help="outputs debugging information instead of hex images", action="store_true")
args = p.parse_args()

parse(read(args.source),symbols,code)
output(code, (args.out if args.out else ""), args)