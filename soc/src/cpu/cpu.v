module cpu(input wire clk,
           input wire reset,

           output reg [15:0] iMemAddress,
           input wire [15:0] iMemOut,
           output wire iMemReadEnable,

           output reg [15:0] dMemIOAddress,
           output reg [7:0] dMemIOIn,
           input wire [7:0] dMemIOOut,
           output wire dMemIOWriteEn,
           output wire dMemIOReadEn,

           input wire interrupt_0,
           input wire interrupt_1,
           input wire interrupt_2,
           input wire interrupt_3,
           output wire interrupt_0_clr,
           output wire interrupt_1_clr,
           output wire interrupt_2_clr,
           output wire interrupt_3_clr,
           output wire reset_out
);
    //***************************************************************
    // Instantiate Control Logic
    control cntrl(.clk(clk),
                  .reset(reset),

                  .iMemOut(iMemOut),

                  .carryFlag(carryFlag),
                  .zeroFlag(zeroFlag),
                  .negativeFlag(negativeFlag),
                  .interruptEnable(interruptEnable),

                  .regFileSrc(regFileSrc),
                  .regFileOutBSelect(regFileOutBSelect),
                  .regFileWriteEnable(regFileWriteEnable),
                  .regFileMove(regFileMove),
                  .regFileAdd(regFileAdd),
                  .regFileConstSrc(regFileConstSrc),

                  .aluSrcASelect(aluSrcASelect),
                  .aluSrcBSelect(aluSrcBSelect),
                  .aluMode(aluMode),

                  .dMemDataSelect(dMemDataSelect),
                  .dMemIOAddressSelect(dMemIOAddressSelect),
                  .dMemIOWriteEn(dMemIOWriteEn),
                  .dMemIOReadEn(dMemIOReadEn),

                  .statusRegSrcSelect(statusRegSrcSelect),
                  .flagEnable(flagEnable),

                  .iMemAddrSelect(iMemAddrSelect),
                  .iMemReadEnable(iMemReadEnable),

                  .pcWriteEn(pcWriteEn),

                  .interruptVector(interruptVector),
                  .interrupt_0(interrupt_0),
                  .interrupt_1(interrupt_1),
                  .interrupt_2(interrupt_2),
                  .interrupt_3(interrupt_3),
                  .interrupt_0_clr(interrupt_0_clr),
                  .interrupt_1_clr(interrupt_1_clr),
                  .interrupt_2_clr(interrupt_2_clr),
                  .interrupt_3_clr(interrupt_3_clr),

                  .reset_out(reset_out)
    );
    //***************************************************************
    // Register File Source Mux
    wire regFileSrc;                            //*
    always @(*) begin
        case(regFileSrc)
        1'b0:   regFileIn = aluOut;             
        1'b1:   regFileIn = dMemIOOut;
        endcase
    end
    //***************************************************************
    // Register File Const Mux
    wire [1:0] regFileConstSrc;                 //*
    always @(*) begin
        case(regFileConstSrc)
        2'b00:  regFileConst = 9'd1;
        2'b01:  regFileConst = 9'd511;
        2'b10:  regFileConst = {iMemOut[15:12],iMemOut[8:4]};
        default regFileConst = {iMemOut[15:12],iMemOut[8:4]};
        endcase
    end
    //***************************************************************
    // Register File
    wire [3:0] regFileOutBSelect;               //*
    reg [7:0] regFileIn;
    wire regFileWriteEnable;                    //*
    wire [7:0] regFileOutA;
    wire [7:0] regFileOutB;
    wire [7:0] regFileOutC;
    wire regFile_cout;
    wire regFile_zout;
    wire regFile_nout;

    wire regFileMove;                           //*
    wire regFileAdd;                            //*
    reg [8:0] regFileConst;

    regFile registerFile(.clk(clk),
                         .reset(reset_out),
                         .din(regFileIn),
                         .a_select(iMemOut[15:12]),
                         .b_select(regFileOutBSelect),
                         .write_en(regFileWriteEnable),
                         .move(regFileMove),
                         .add(regFileAdd),
                         .constant(regFileConst),
                         .outA(regFileOutA),
                         .outB(regFileOutB),
                         .outC(regFileOutC),
                         .cout(regFile_cout),
                         .zout(regFile_zout),
                         .nout(regFile_nout)
    );
    //***************************************************************
    // ALU Mux A
    wire aluSrcASelect;                         //*
    always @(*) begin
        case(aluSrcASelect)
        1'b0:   dataA = regFileOutA;            // From the register file
        1'b1:   dataA = {4'd0,statusOut};       // From zero-extended status register
        endcase
    end
    //***************************************************************
    // ALU Mux B
    wire [1:0] aluSrcBSelect;                   //*
    always @(*) begin
        case(aluSrcBSelect)
        2'b00:  dataB = regFileOutB;            // From the register file
        2'b01:  dataB = {4'd0,iMemOut[11:8]};   // From immediate 4-bit mask
        2'b10:  dataB = iMemOut[11:4];          // From immediate 8-bit data
        2'b11:  dataB = 8'd0;                   // Default to zero
        endcase
    end
    //***************************************************************
    // ALU
    wire [3:0] aluMode;                         //*
    wire alu_cout;
    wire alu_zout;
    wire alu_nout;
    wire [7:0] aluOut;
    reg [7:0] dataA;
    reg [7:0] dataB;

    alu ALU(.dataA(dataA),
            .dataB(dataB),
            .mode(aluMode),
            .cin(carryFlag),
            .out(aluOut),
            .cout(alu_cout),
            .zout(alu_zout),
            .nout(alu_nout)
    );
    //***************************************************************
    // Data Memory and I/O Data Mux
    wire [2:0] dMemDataSelect;                  //*
    always @(*) begin
        case(dMemDataSelect)
            3'b000:  dMemIOIn = aluOut;                 // From the ALU
            3'b001:  dMemIOIn = pcPlusOne[15:8];        // From MSBs of the PC + 1
            3'b010:  dMemIOIn = pcPlusOne[7:0];         // From LSBs of the PC + 1
            3'b011:  dMemIOIn = current_address[15:8];  // From MSBs of the current address
            3'b100:  dMemIOIn = current_address[7:0];   // From LSBs of the current address
            default  dMemIOIn = current_address[7:0];
        endcase
    end
    //***************************************************************
    // Data Memory and I/O Address Mux
    wire [1:0] dMemIOAddressSelect;             //*
    always @(*) begin
        case(dMemIOAddressSelect)
            2'b00:   dMemIOAddress = {regFileOutC,regFileOutB};                                     // BC pointer
            2'b01:   dMemIOAddress = {8'b00010000,iMemOut[11:4]};                                   // IO address
            2'b10:   dMemIOAddress = {regFileOutC,regFileOutB} + 16'b1;                             // BC pointer + 1
            2'b11:   dMemIOAddress = {regFileOutC,regFileOutB} + {{11{iMemOut[8]}},iMemOut[8:4]};   // BC pointer + k
        endcase
    end
    //***************************************************************
    // Flag Out Mux
    wire cout = (regFileAdd) ? regFile_cout : alu_cout;
    wire zout = (regFileAdd) ? regFile_zout : alu_zout;
    wire nout = (regFileAdd) ? regFile_nout : alu_nout;
    //***************************************************************
    // Status Register Source Mux
    wire [1:0] statusRegSrcSelect;              //*
    always @(*) begin
        case(statusRegSrcSelect)
        2'b00:  statusIn = {interruptEnable,nout,zout,cout};               // ALU flags out and save interrupt enable status
        2'b01:  statusIn = {aluOut[3:0]};                                  // ALU output
        2'b10:  statusIn = {dMemIOOut[3:0]};                               // Data memory output
        2'b11:  statusIn = {1'b0,negativeFlag,zeroFlag,carryFlag};         // Disable interrupts and save all other flags
        endcase
    end
    //***************************************************************
    // Status Register
    reg carryFlag = 0;
    reg zeroFlag = 0;
    reg negativeFlag = 0;
    reg interruptEnable = 0;
    wire flagEnable;                            //*
    reg [3:0] statusIn;
    wire [3:0] statusOut = {interruptEnable,negativeFlag,zeroFlag,carryFlag};

    always @(posedge clk) begin
        if(reset_out) begin
            carryFlag <= 0;
            zeroFlag <= 0;
            negativeFlag <= 0;
            interruptEnable <= 0;
        end
        else if(flagEnable) begin
            carryFlag <= statusIn[0];
            zeroFlag <= statusIn[1];
            negativeFlag <= statusIn[2];
            interruptEnable <= statusIn[3];
        end
    end
    //***************************************************************
    // Return Register
    reg [7:0] returnReg = 0;
    always @(posedge clk) begin
        returnReg <= dMemIOOut;
    end 
    //***************************************************************
    // Current Address Register
    reg [15:0] current_address;
    always @(posedge clk) begin
        if(reset_out) begin
            current_address <= 0;
        end
        else if(iMemReadEnable) begin
            current_address <= iMemAddress;
        end
    end
    //***************************************************************
    // Instruction Memory Address Mux
    wire [15:0] interruptVector;
    wire [2:0] iMemAddrSelect;                  //*
    always @(*) begin
        case(iMemAddrSelect)
        3'b000:     iMemAddress = pcOut;
        3'b001:     iMemAddress = pcPlusOne;
        3'b010:     iMemAddress = interruptVector;
        3'b011:     iMemAddress = iMemOut;
        3'b100:     iMemAddress = {regFileOutC, regFileOutB};
        3'b101:     iMemAddress = {returnReg,dMemIOOut};
        3'b110:     iMemAddress = current_address + {{7{iMemOut[12]}},iMemOut[12:4]};
        default     iMemAddress = 16'd0;      
        endcase
    end
    //***************************************************************
    // PC and pcPlusOne adder
    reg [15:0] pc = 16'd0;
    wire [15:0] pcIn = iMemAddress + 1;
    wire [15:0] pcOut = pc;
    wire [15:0] pcPlusOne = pcOut + 1;
    wire pcWriteEn;                             //*
    always @(posedge clk) begin
        if(pcWriteEn) begin
            if(reset_out) begin
                pc <= 16'd0;
            end
            else begin
                pc <= pcIn; 
            end
        end
    end
    //***************************************************************    
endmodule