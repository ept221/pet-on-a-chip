module control(input wire clk,
               input wire reset,
               input wire [15:0] iMemOut,
               input wire carryFlag,
               input wire zeroFlag,
               input wire negativeFlag,
               input wire interruptEnable,
               output reg regFileSrc,
               output reg [3:0] regFileOutBSelect,
               output reg regFileWriteEnable,
               output wire regFileMove,
               output reg regFileAdd,
               output reg [1:0] regFileConstSrc,            
               output reg aluSrcASelect,
               output reg [1:0] aluSrcBSelect,
               output reg [3:0] aluMode,
               output reg [2:0] dMemDataSelect,
               output reg [1:0] dMemIOAddressSelect,
               output reg dMemIOWriteEn,
               output reg dMemIOReadEn,
               output reg [1:0] statusRegSrcSelect,
               output reg flagEnable,
               output reg [2:0] iMemAddrSelect,
               output reg iMemReadEnable,
               output reg pcWriteEn,
               output reg [15:0] interruptVector,
               input wire interrupt_0,
               input wire interrupt_1,
               input wire interrupt_2,
               input wire interrupt_3,
               output reg interrupt_0_clr,
               output reg interrupt_1_clr,
               output reg interrupt_2_clr,
               output reg interrupt_3_clr,
               output wire reset_out
);    
    //****************************************************************************************************
    // States
    localparam PART1 = 4'b0000;           // Part 1 of instruction (may be single or multi-cycle)
    localparam PART2 = 4'b0010;           // Part 2 of generic multi-cycle instruction
    localparam PART3 = 4'b0100;           // Part 3 of generic multi-cycle instruction

    localparam JMP = 4'b0001;             // Fetch address, and perform a jump
    localparam CALL = 4'b0011;            // Fetch address, and perform a call
    localparam INTERRUPT = 4'b0101;       // Push MSBs of return address, and jump to the ISR
    localparam START = 4'b0111;           // Initial state, wait 40 cycles, and fetch first instruction
    localparam RESET = 4'b1001;           // Reset State

    reg [3:0] state = START;
    reg [3:0] nextState;
    always @(posedge clk) begin
        state <= nextState;
    end
    //****************************************************************************************************
    // Reset Control
    reg reset_d0 = 1;
    reg reset_d1 = 1;
    always @(posedge clk) begin
        reset_d0 <= reset;
        reset_d1 <= reset_d0;
    end

    assign reset_out = (state[3:1] == RESET[3:1] || state[3:1] == START[3:1]);
    //****************************************************************************************************
    // Delayed start counter
    reg [5:0] delay = 0;
    always @(posedge clk) begin
        if(state == START) begin
            delay = delay + 1;
        end
        else begin
            delay <= 0;
        end
    end
    //****************************************************************************************************
    // Logic for jmp, call, and ret conditions
    reg condition;
    always @(*) begin
        case(iMemOut[15:13])
        3'b000:    condition = 1'b1;
        3'b001:    condition = (carryFlag);
        3'b010:    condition = (~carryFlag);
        3'b011:    condition = (zeroFlag);
        3'b100:    condition = (~zeroFlag);
        3'b101:    condition = (negativeFlag);
        3'b110:    condition = (~negativeFlag);
        3'b111:    condition = 1'b1;
        endcase 
    end
    //****************************************************************************************************
    // Interrupt vectoring
    always @(*) begin
        if(interrupt_0) begin
            interruptVector = 16'd20;
        end
        else if(interrupt_1) begin
            interruptVector = 16'd30;
        end
        else if(interrupt_2) begin
            interruptVector = 16'd40;
        end
        else if(interrupt_3) begin
            interruptVector = 16'd50;
        end
        else begin
            interruptVector = 16'd0;
        end
    end

    always @(*) begin
        if(state == INTERRUPT && interrupt_0) begin
            interrupt_0_clr = 1;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_1) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 1;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_2) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 1;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_3) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 1;
        end
        else begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
    end

    wire interrupt = interrupt_0 || interrupt_1 || interrupt_2 || interrupt_3;

    //****************************************************************************************************
    // Main Decoder
    wire R_I_TYPE =   (iMemOut[3:0] >= 4'b001 && iMemOut[3:0] <= 4'b0111);
    wire IO_TYPE =    (iMemOut[3:0] == 4'b1000 || iMemOut[3:0] == 4'b1001);
    wire R_R_TYPE =   (iMemOut[3:0] == 4'b1010 && iMemOut[7:4] >= 4'b0001 && iMemOut[7:4] <= 4'b1001);
    wire R_P_TYPE =   (iMemOut[3:0] == 4'b1010 && iMemOut[7:4] >= 4'b1100 && iMemOut[7:4] <= 4'b1111 && iMemOut[8] == 1'b0);
    wire R_P_K_TYPE = (iMemOut[3:0] == 4'b1011 || iMemOut[3:0] == 4'b1100);
    wire P_I_TYPE =   (iMemOut[3:0] == 4'b1101);
    wire BR_TYPE =    (iMemOut[3:0] == 4'b1110);
    wire R_TYPE =     (iMemOut[3:0] == 4'b1111 && iMemOut[7:4] >= 4'b1010 && iMemOut[7:4] <= 4'b1111 && iMemOut[11:8] == 4'b0000);
    wire JMPI_TYPE =  (iMemOut[8:0] == 9'b0_0001_1111 && iMemOut[12] == 1'b0);
    wire JMP_TYPE =   (iMemOut[12:0] == 13'b0_1110_0010_1111);
    wire CALL_TYPE =  (iMemOut[12:0] == 13'b0_1110_0011_1111);
    wire RET_TYPE =   (iMemOut[12:0] == 13'b0_1110_0100_1111);
    wire PUS_TYPE =   (iMemOut[15:0] == 16'b0000_1110_0101_1111);
    wire POS_TYPE =   (iMemOut[15:0] == 16'b0000_1110_0110_1111);
    wire M_TYPE =     (iMemOut[7:0] == 8'b0111_1111 || iMemOut[7:0] == 8'b1000_1111) && (iMemOut[15:12] == 4'b0000);
    wire P_P_TYPE =   (iMemOut[12] == 1'b0 && iMemOut[8:0] == 9'b0_1001_1111);
    wire POP_TYPE =   (iMemOut[11:0] == 12'b1110_0010_0000);
    wire NOP_TYPE =   (iMemOut[15:0] == 16'b0000_0000_0000_0000);
    wire HLT_TYPE =   (iMemOut[15:0] == 16'b1111_1111_1111_1111);
    //****************************************************************************************************
    // The HLT instruction cannot be interrupted, and neither can the clear status register
    // instruction (CSR), if it is clearing the global interrupt enable flag.
    wire uninterruptible = (HLT_TYPE) || (RET_TYPE) || (iMemOut[15:11] == 4'b0 && iMemOut[7:0] == 8'b10001111);
    //****************************************************************************************************
    assign regFileMove = P_P_TYPE;
    //****************************************************************************************************
    always @(*) begin
        if(state[0] == 1'b0) begin
            if(reset_d1 == 1'b0 && state != START && state != RESET) begin
                regFileSrc = 1'b0;                  // aluOut
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass A, doesn't matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                dMemIOWriteEn = 1'd0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                iMemReadEnable = 1'b0;              // Wait till second stage to make the jump
                pcWriteEn = 1'd0;
                nextState = RESET;
            end
            else if(interruptEnable && state == PART1 && interrupt && ~uninterruptible) begin
                regFileSrc = 1'b0;                  // aluOut
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b1;                  // Need to push to the stack
                regFileConstSrc = 2'b01;            // SP--
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass A, doesn't matter
                dMemDataSelect = 3'b100;            // From LSBs of the current address
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                dMemIOWriteEn = 1'd1;               // Need to push to the stack
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                flagEnable = 1'b1;                  // Disable interrupts
                iMemAddrSelect = 3'b010;            // interruptVector
                iMemReadEnable = 1'b0;              // Wait till second stage to make the jump
                pcWriteEn = 1'd0;
                nextState = INTERRUPT;
            end
            else if(R_I_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b1;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;             // Doesn't matter
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b10;              // From immediate 8-bit data
                aluMode = {1'b0,iMemOut[2:0]};
                dMemDataSelect = 3'b000;            // aluOut, doesn't matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't matter
                dMemIOWriteEn = 1'd0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = (iMemOut[2:0] != 3'b001);  // Don't set flags on LDI
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'd1;
                nextState = PART1;
            end
            else if(IO_TYPE) begin
                regFileSrc = 1'b1;                  // dMemIOOut
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter.
                regFileWriteEnable = (state == PART2);
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b01;        // {8'd0,iMemOut[11:4]};
                dMemIOWriteEn = iMemOut[0];         // If out
                dMemIOReadEn = (~iMemOut[0] && (state == PART1));   // If In and PART1
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status, doesn't matter.
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                iMemReadEnable = (iMemOut[0] || state == PART2);  // If OUT or if IN and PART2
                pcWriteEn = (iMemOut[0] || state == PART2);       // If OUT or if IN and PART2
                nextState = (~iMemOut[0] && (state == PART1)) ? PART2 : PART1;
            end
            else if(R_R_TYPE || R_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut
                regFileOutBSelect = iMemOut[11:8];  // SSSS, or in the case of Type R, just 0000
                regFileWriteEnable = 1'b1;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = iMemOut[7:4];
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, but doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = (iMemOut[7:4] != 4'b0001);   // MOV doesn't affect flags
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(R_P_TYPE) begin
                regFileSrc = 1'b1;                  // dMemIOOut
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // PPP0
                regFileWriteEnable = iMemOut[5];    // If Load
                regFileAdd = (state == PART1);
                regFileConstSrc = (iMemOut[4] == 1'b0) ? 2'b00 : 2'b01;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}
                dMemIOWriteEn = ~iMemOut[5];        // If Store
                dMemIOReadEn = (iMemOut[5] && (state == PART1));    // If Load and PART1
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = (~iMemOut[5] || (state == PART2)); // If Store or PART2 of Load
                pcWriteEn = (~iMemOut[5] || (state == PART2)); // If Store or PART2 of Load
                nextState = (iMemOut[5] && (state == PART1)) ? PART2 : PART1;
            end
            else if(R_P_K_TYPE) begin
                regFileSrc = 1'b1;                  // dMemIOOut
                regFileOutBSelect = {iMemOut[11:9],1'b0};    // PPP0
                regFileWriteEnable = (state == PART2);       // If PART2 of Load
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b11;        // BC pointer + k
                dMemIOWriteEn = iMemOut[0];         // If Store
                dMemIOReadEn = (~iMemOut[0] && (state == PART1));   // If Load and PART1
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = (iMemOut[0] || (state == PART2));  // If Store or PART2 of Load
                pcWriteEn = (iMemOut[0] || (state == PART2));  // If Store or PART2 of Load
                nextState = (~iMemOut[0] && (state == PART1)) ? PART2 : PART1;
            end
            else if(P_I_TYPE) begin
                regFileSrc = 1'b0;                          // aluOut, doesn't matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};   // PPP0
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b1;
                regFileConstSrc = 2'b10;
                aluSrcASelect = 1'b0;                       // regFileOutA, doesn't really matter
                aluSrcBSelect = 2'b00;                      // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                          // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;                    // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;                // BC pointer, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;                 // ALU flags out and save interrupt enable status
                flagEnable = 1'b1;
                iMemAddrSelect = 3'b000;                    // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(BR_TYPE || JMPI_TYPE) begin
                regFileSrc = 1'b0;                          // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};   // Doesn't matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;                       // regFileOutA, doesn't really matter
                aluSrcBSelect = 2'b00;                      // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                          // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;                    // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;                // {regFileOutC,regFileOutB}
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;                 // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = (condition) ? ((~iMemOut[0]) ? 3'b110 : 3'b100) : 3'b000;
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(JMP_TYPE) begin
                regFileSrc = 1'b0;                              // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};       // Doesn't matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;                           // regFileOutA, doesn't really matter
                aluSrcBSelect = 2'b00;                          // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                              // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;                        // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;                    // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;                     // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = (condition) ? 3'b000 : 3'b001; // ? pcOut : pcPlusOne
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = (condition) ? JMP : PART1;
            end
            else if(CALL_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileAdd = condition;
                regFileConstSrc = 2'b01;
                aluSrcASelect = 1'b0;               // From the register file, doesn't really matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b010;            // From LSBs of the PC + 1
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                dMemIOWriteEn = condition;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = (condition) ? 3'b000 : 3'b001;
                iMemReadEnable = 1'b1;
                pcWriteEn = ~condition;             // Dont write to the PC if condition, because we still need to get the MSBs
                nextState = (condition) ? CALL : PART1;
            end
            else if(RET_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // lower SP reg so outputs SP for BC
                regFileWriteEnable = 1'b0;
                regFileAdd = (state == PART1 && condition) || (state == PART2);
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b10;        // {regFileOutC,regFileOutB} + 1, SP + 1
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = (state == PART1 && condition) || (state == PART2);
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = (state == PART1) ? 3'b000 : 3'b101;   // PART1: pcOut, PART2 || PART3: {returnReg,dMemIOOut}
                iMemReadEnable = (state == PART1 && ~condition) || (state == PART3);
                pcWriteEn = (state == PART1 && ~condition) || (state == PART3);
                nextState = ((state == PART1 && ~condition) || (state == PART3)) ? PART1 : ((state == PART1) ? PART2 : PART3);
            end
            else if(PUS_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // lower SP reg so outputs SP for BC
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b1;
                regFileConstSrc = 2'b01;
                aluSrcASelect = 1'b1;               // From zero-extended status register
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b00;        // BC pointer
                dMemIOWriteEn = 1'b1;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(POS_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // lower SP reg so outputs SP for BC
                regFileWriteEnable = 1'b0;
                regFileAdd = (state == PART1);
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // From register file, doesn't really matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b10;        // {regFileOutC,regFileOutB} + 1
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = (state == PART1);
                statusRegSrcSelect = 2'b10;         // dMemIOOut[3:0]
                flagEnable = (state == PART2);
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = (state == PART2);
                pcWriteEn = (state == PART2);
                nextState = (state == PART1) ? PART2 : PART1;
            end
            else if(M_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b1;               // From zero-extended status register
                aluSrcBSelect = 2'b01;              // {4'd0,iMemOut[11:8]}, immediate 4-bit mask
                aluMode = (~iMemOut[7]) ? 4'b0011 : 4'b0010;
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b01;         // ALU output
                flagEnable = 1'b1;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(P_P_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA, doesn't matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't matter
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            else if(POP_TYPE) begin
                regFileSrc = 1'b1;                  // dMemIOOut
                regFileOutBSelect = {iMemOut[11:9],1'b0}; // lower SP reg
                regFileWriteEnable = (state == PART2);    // Write during PART2
                regFileAdd = (state == PART1);      // Increment during PART1
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA, doesn't matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't matter
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b10;        // {regFileOutC,regFileOutB} + 1
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = (state == PART1);    // Read during PART1
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = (state == PART2);
                pcWriteEn = (state == PART2);
                nextState = (state == PART1) ? PART2 : PART1;
            end
            else if(NOP_TYPE || HLT_TYPE) begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = ~iMemOut[0];
                pcWriteEn = ~iMemOut[0];
                nextState = PART1;
            end
            else begin
                regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileAdd = 1'b0;
                regFileConstSrc = 2'b00;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass A, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
        end
        else begin
            case(state[3:1])
                RESET[3:1]: begin
                    regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                    regFileOutBSelect = {iMemOut[11:9],1'b0}; // Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b0;
                    regFileConstSrc = 2'b00;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass A, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1;
                    nextState = (reset_d1 == 1'd1) ? PART1 : RESET;
                end
                START[3:1]: begin
                    regFileSrc = 1'b0;                         // aluOut, doesn't really matter
                    regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b0;
                    regFileConstSrc = 2'b00;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass A, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = (delay == 6'd40) ? 1 : 0;
                    nextState = (delay == 6'd40) ? PART1 : START;
                end
                INTERRUPT[3:1]: begin
                    regFileSrc = 1'b0;                  // aluOut
                    regFileOutBSelect = 4'b1110;        // lower SP reg
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b1;                  // SP--
                    regFileConstSrc = 2'b01;            // SP--
                    aluSrcASelect = 1'b0;               // From the register file
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass A
                    dMemDataSelect = 3'b011;            // From MSBs of the current address
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                    dMemIOWriteEn = 1'd1;               // Need to push to the stack
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;                  // Need to disable interrupts
                    iMemAddrSelect = 3'b010;            // interruptVector
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'd1;
                    nextState = PART1;
                end
                JMP[3:1]: begin
                    regFileSrc = 1'b0;                              // aluOut, doesn't really matter
                    regFileOutBSelect = {iMemOut[11:9],1'b0};       // same as inSelect, doesn't matter
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b0;
                    regFileConstSrc = 2'b00;
                    aluSrcASelect = 1'b1;                           // From zero-extended status register
                    aluSrcBSelect = 2'b00;                          // regFileOutB, doesn't really matter
                    aluMode = 4'b0000;                              // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;                        // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;                    // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;                     // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    iMemAddrSelect = 3'b011;                        // iMemOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
                CALL[3:1]: begin
                    regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                    regFileOutBSelect = 4'b1110;        // lower SP reg
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b1;
                    regFileConstSrc = 2'b01;            // Deincrement the SP
                    aluSrcASelect = 1'b0;               // From the register file, doesn't really matter
                    aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;     // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    dMemDataSelect = 3'b001;        // From MSBs of the PC + 1
                    iMemReadEnable = 1'b1;          // read the instruction at the address we call to
                    dMemIOWriteEn = 1'b1;           // Write the MSBs of the PC to the stack
                    iMemAddrSelect = 3'b011;        // iMemOut, the address of the place we call to
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
                default begin
                    regFileSrc = 1'b0;                  // aluOut, doesn't really matter
                    regFileOutBSelect = {iMemOut[11:9],1'b0};  // Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileAdd = 1'b0;
                    regFileConstSrc = 2'b00;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            endcase
        end
    end
endmodule