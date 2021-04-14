module regFile(input wire clk,
               input wire reset,
               input wire [7:0] din,
               input wire [3:0] a_select,
               input wire [3:0] b_select,
               input wire write_en,
               input wire move,
               input wire add,
               input wire [8:0] constant,
               output wire [7:0] outA,
               output wire [7:0] outB,
               output reg [7:0] outC,
               output wire cout,
               output wire zout,
               output wire nout
);
    //****************************************************************************************
    // Construct the register file and initialize it to zero
    reg [7:0] rFile [0:15];
    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) begin
            rFile[i] = 8'd0;
        end
    end
    //****************************************************************************************
    always @(posedge clk) begin
        if(reset) begin
            for(i = 0; i < 16; i = i + 1) begin
                rFile[i] <= 0;
            end
        end
        else begin
            if(write_en && ~move) begin
                rFile[a_select] <= din;
            end
            if(add && (~write_en || (write_en && ~(b_select == a_select))) && ~move) begin
                case(b_select)
                    4'b0000:    {rFile[1],rFile[0]} <= result;
                    4'b0010:    {rFile[3],rFile[2]} <= result;
                    4'b0100:    {rFile[5],rFile[4]} <= result;
                    4'b0110:    {rFile[7],rFile[6]} <= result;
                    4'b1000:    {rFile[9],rFile[8]} <= result;
                    4'b1010:    {rFile[11],rFile[10]} <= result;
                    4'b1100:    {rFile[13],rFile[12]} <= result;
                    4'b1110:    {rFile[15],rFile[14]} <= result;
                endcase
            end
            else if(move) begin
                case(a_select)
                    4'b0000:    {rFile[1],rFile[0]} <= b_pair;
                    4'b0010:    {rFile[3],rFile[2]} <= b_pair;
                    4'b0100:    {rFile[5],rFile[4]} <= b_pair;
                    4'b0110:    {rFile[7],rFile[6]} <= b_pair;
                    4'b1000:    {rFile[9],rFile[8]} <= b_pair;
                    4'b1010:    {rFile[11],rFile[10]} <= b_pair;
                    4'b1100:    {rFile[13],rFile[12]} <= b_pair;
                    4'b1110:    {rFile[15],rFile[14]} <= b_pair;
                endcase
            end
        end
    end

    wire [15:0] result;
    assign {cout, result} = b_pair + {{7{constant[8]}},constant};
    assign zout = (result == 16'b0);
    assign nout = result[14];

    assign outA = rFile[a_select];
    assign outB = rFile[b_select];
    //****************************************************************************************
    reg [15:0] a_pair;
    always @(*) begin
        case(a_select[3:1])
        3'b000: begin
            a_pair = {rFile[1],rFile[0]};
        end
        3'b001: begin
            a_pair = {rFile[3],rFile[2]};
        end    
        3'b010: begin
            a_pair = {rFile[5],rFile[4]};
        end    
        3'b011: begin
            a_pair = {rFile[7],rFile[6]};
        end
        3'b100: begin
            a_pair = {rFile[9],rFile[8]};
        end    
        3'b101: begin
            a_pair = {rFile[11],rFile[10]};
        end
        3'b110: begin
            a_pair = {rFile[13],rFile[12]};
        end
        3'b111: begin
            a_pair = {rFile[15],rFile[14]};
        end
        default begin
            a_pair = 0;
        end
        endcase
    end
    //****************************************************************************************
    reg [15:0] b_pair;
    always @(*) begin
        case(b_select[3:1])
        3'b000: begin
            b_pair = {rFile[1],rFile[0]};
            outC = rFile[1];
        end
        3'b001: begin
            b_pair = {rFile[3],rFile[2]};
            outC = rFile[3];
        end    
        3'b010: begin
            b_pair = {rFile[5],rFile[4]};
            outC = rFile[5];
        end    
        3'b011: begin
            b_pair = {rFile[7],rFile[6]};
            outC = rFile[7]; 
        end
        3'b100: begin
            b_pair = {rFile[9],rFile[8]};
            outC = rFile[9];
        end    
        3'b101: begin
            b_pair = {rFile[11],rFile[10]};
            outC = rFile[11];
        end
        3'b110: begin
            b_pair = {rFile[13],rFile[12]};
            outC = rFile[13]; 
        end
        3'b111: begin
            b_pair = {rFile[15],rFile[14]};
            outC = rFile[15];
        end
        default begin
            b_pair = 0;
            outC = 0;
        end
        endcase
    end
    //****************************************************************************************
endmodule