module alu(input wire [7:0] dataA,
           input wire [7:0] dataB,
           input wire [3:0] mode,
           input wire cin,
           output reg [7:0] out,
           output reg cout,
           output reg zout,
           output reg nout
);

    always @(*) begin
        case(mode)
        4'b0000:    {cout, out} = {cin,dataA};                  // Pass A
        4'b0001:    {cout, out} = {cin,dataB};                  // Pass B       // Used by LDI and MOV
        4'b0010:    {cout, out} = {cin,dataA & dataB};          // AND 
        4'b0011:    {cout, out} = {cin,dataA | dataB};          // OR
        4'b0100:    {cout, out} = {cin,dataA ^ dataB};          // XOR
        4'b0101:    {cout, out} = dataA + dataB;                // ADD
        4'b0110:    {cout, out} = dataA + dataB + {7'b0,cin};   // ADC
        4'b0111:    {cout, out} = {(dataA > dataB),dataA};      // CMP          // Sets carry on greater, passes dataA
        4'b1000:    {cout, out} = dataA - dataB;                // SUB
        4'b1001:    {cout, out} = dataA - dataB - {7'b0,cin};   // SBB
        4'b1010:    {cout, out} = (dataA << 1);                 // SLL
        4'b1011:    {cout, out} = {dataA[0],(dataA >> 1)};      // SRL
        4'b1100:    {cout, out} = {dataA[0],(dataA >>> 1)};     // SRA
        4'b1101:    {cout, out} = {dataA,cin};                  // RLC
        4'b1110:    {out, cout} = {cin,dataA};                  // RRC
        4'b1111:    {cout, out} = {cin,~dataA};                 // NOT
        endcase
    end

    always @(*) begin
        if(mode == 4'b0111) begin       // If CMP
            zout = (dataA == dataB);
            nout = (dataA < dataB);
        end
        else begin
            zout = (out == 8'd0);
            nout = out[7];
        end

    end
endmodule