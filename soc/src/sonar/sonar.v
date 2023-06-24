module sonar(input clk,
             input wire [7:0] din,
             input wire [7:0] address,
             input wire w_en,
             input wire r_en,
             output reg [7:0] dout,
             input wire echo,
             output wire trig
);
    //*********************************************
    parameter SONAR_ADDRESS = 8'h00;
    localparam CONTROL_ADDRESS = SONAR_ADDRESS;
    localparam RANGE_ADDRESS = SONAR_ADDRESS + 1;
    //*********************************************
    reg [7:0] status = 0;
    reg [7:0] range = 0;
    always @(posedge clk) begin
        case(address)
            CONTROL_ADDRESS: begin
                if(r_en) begin
                    dout <= status;
                end
            end
            RANGE_ADDRESS: begin
                if(r_en) begin
                    dout <= range;
                end
            end
            default begin
                dout <= 0;
            end
        endcase
    end

    wire cond = (((!echo) || (count == 16'h88b8)) && (state == 2'b10) && scaled);
    always @(posedge clk) begin
        if(cond) begin
            status <= 8'd0;
        end
        else if(address == CONTROL_ADDRESS && w_en) begin
            status <= din;
        end
    end
    //*********************************************
    // Prescaler

    // If you want to get the ceil of x/y via truncation,
    // apparently you can do (x+y-1)/y.

    parameter CLK_FREQ = 16000000;
    localparam SCALE_FACTOR = (CLK_FREQ+1000000-1)/1000000;
    localparam WIDTH = $clog2(SCALE_FACTOR);
    wire [WIDTH:0] scale_factor = SCALE_FACTOR;


    reg scaled = 0;
    reg [WIDTH:0] prescaler = 0;
    always @(posedge clk) begin
        if(prescaler == scale_factor - 1) begin
            prescaler <= 0;
            scaled <= 1;
        end
        else begin
            prescaler <= prescaler + 1;
            scaled <= 0;
        end
    end
    //*************************************************************************************
    // FSM
    //
    // The speed of sound is 0.013396 inches per microsecond.
    // The range can then be calculated by (count/2)(0.013396) or count(0.006698).
    // 0.006698 decimal is about 0.000000011011011 binary which is exactly 219/32768.
    // The most error using this approximation will happen at count = 35ms.
    // We can calulate the max error as follows: 35000(0.006698 - 219/32768) which is
    // about 0.5 inches.
    reg [15:0] count = 0;
    wire [23:0] inches = count*219;     
    // The upper 9 bits are the integer portion
    // The lower 15 bits are the fractional portion
    // Since the maximum range is just under 234 inches
    // we only need to report 8-bits for the integer portion

    reg [1:0] state = 2'b00;
    assign trig = (state == 2'b0) && (status[0] == 1'b1);
    always @(posedge clk) begin
        if(scaled) begin
            case(state)
            2'b00:                                  // 10us trigger pulse 
                begin
                    if(status[0]) begin
                        if(count == 16'h9) begin    
                            state <= 2'b01;
                            count <= 0;
                        end
                        else begin
                            count <= count + 1;
                        end
                    end
                end
            2'b01:                                  // wait for echo to start
                begin
                    if(echo) begin
                        state <= 2'b10;
                    end
                end
            2'b10:
                begin                               // wait for end of echo or 35ms
                    if((!echo) || (count == 16'h88b8)) begin
                        state <= 2'b11;
                        range <= inches[22:15];
                    end
                    count <= count + 1;
                end
            2'b11:
                begin                               // wait till 60 ms have passed since the start of the echo
                    if(count == 16'hEA5F) begin
                        state <= 2'b00;
                        count <= 16'd0;
                    end
                    else begin
                        count <= count + 1;
                    end
                end
            endcase
        end
    end
    //*********************************************
endmodule