module counter_timer(input wire clk,
                     input wire rst,
                     input wire [7:0] din,
                     input wire [7:0] address,
                     input wire w_en,
                     input wire r_en,
                     output reg [7:0] dout,
                     output reg out0 = 0,
                     output reg out1 = 0,
                     output wire out0_en,
                     output wire out1_en,
                     output wire top_flag = 0,
                     output wire match0_flag = 0,
                     output wire match1_flag = 0
);
    //*********************************************************************************************
    parameter COUNTER_TIMER_ADDRESS = 8'h00;
    localparam SCALE_FACTOR_LSB_ADDRESS = COUNTER_TIMER_ADDRESS;
    localparam SCALE_FACTOR_MSB_ADDRESS = COUNTER_TIMER_ADDRESS + 1;
    localparam COUNTER_CONTROL_ADDRESS = COUNTER_TIMER_ADDRESS + 2;
    localparam CMPR0_ADDRESS = COUNTER_TIMER_ADDRESS + 3;
    localparam CMPR1_ADDRESS = COUNTER_TIMER_ADDRESS + 4;
    localparam COUNTER_ADDRESS = COUNTER_TIMER_ADDRESS + 5;
    localparam INTERRUPT_FLAGS_ADDRESS = COUNTER_TIMER_ADDRESS + 6;
    //*********************************************************************************************
    // Prescaler registeres
    reg [15:0] scaleFactor = 0;
    reg [15:0] prescaler = 0;

    // Counter/Timer registers
    reg [7:0] counterControl = 0;
    reg [7:0] cmpr0 = 0;
    reg [7:0] cmpr1 = 0;
    reg [7:0] counter = 0;

    // External signals
    assign out0_en = counterControl[2];
    assign out1_en = counterControl[3];

    // Internal signals 
    wire match0;
    wire match1;
    wire top;
    reg scaled = 0;
    //*********************************************************************************************
    // Prescaler
    always @(posedge clk) begin
        if(rst) begin
            scaled <= 0;
            prescaler <= 0;
        end
        else if(prescaler == scaleFactor) begin
            scaled <= 1;
            prescaler <= 0;
        end
        else begin
            scaled <= 0;
            prescaler <= prescaler + 1;
        end
    end
    //*********************************************************************************************
    // Counter/Timer
    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            out0 <= 0;
            out1 <= 0;
        end
        else if(scaled) begin
            if(counterControl[1:0] == 2'b00) begin          // Idle mode
                counter <= 0;                               // Clear the counter
                out0 <= 0;
                out1 <= 0;
            end
            else if(counterControl[1:0] == 2'b01) begin     // CTC mode
                if(match0) begin                            // On match0:
                    counter <= 0;                           // Reset the counter
                    out0 <= ~out0;                          // Toggle the output
                end
                else begin
                    counter <= counter + 1;
                end
            end
            else if(counterControl[1:0] == 2'b10) begin     // PWM mode
                if(counter == 8'd255) begin                 // If finished 256 cycles
                    out0 <= 1;                              // On next edge (start of zero), set the outputs to 1
                    out1 <= 1;
                end
                else begin
                    if(match0) begin                        // On match0:
                        out0 <= 0;                          // clear out0
                    end
                    if(match1) begin                        // On match1:
                        out1 <= 0;                          // clear out1
                    end
                end
                counter <= counter + 1;
            end
        end
    end
    //*********************************************************************************************
    // Comparators
    assign top = (counter == 255) ? 1 : 0;
    assign match0 = (counter == cmpr0) ? 1 : 0;
    assign match1 = (counter == cmpr1) ? 1 : 0;
    //*********************************************************************************************
    // Interrupts
    reg top_old;
    reg match0_old;
    reg match1_old;
    always @(posedge clk) begin
        if(rst) begin
            top_old <= 0;
            match0_old <= 0;
            match1_old <= 0;
        end
        else begin
            // Needed to detect edges
            top_old <= top;
            match0_old <= match0;
            match1_old <= match1;
        end
    end
    assign top_flag = (top && (~top_old) && counterControl[4]);
    assign match0_flag = (match0 && (~match0_old) && counterControl[5]);
    assign match1_flag = (match1 && (~match1_old) && counterControl[6]);
    //*********************************************************************************************
    always @(posedge clk) begin
        if(rst) begin
            scaleFactor[7:0] <= 0;
            dout <= 0;
            scaleFactor[15:8] <= 0;
            counterControl <= 0;
            cmpr0 <= 0;
            cmpr1 <= 0;
        end
        else begin
            case(address)
                SCALE_FACTOR_LSB_ADDRESS: begin
                    if(w_en) begin
                        scaleFactor[7:0] <= din;
                    end
                    if(r_en) begin
                        dout <= scaleFactor[7:0];
                    end
                end
                SCALE_FACTOR_MSB_ADDRESS: begin
                    if(w_en) begin
                        scaleFactor[15:8] <= din;
                    end
                    if(r_en) begin
                        dout <= scaleFactor[15:8];
                    end
                end
                COUNTER_CONTROL_ADDRESS: begin
                    if(w_en) begin
                        counterControl <= din;
                    end
                    if(r_en) begin
                        dout <= counterControl;
                    end
                end
                CMPR0_ADDRESS: begin
                    if(w_en) begin
                        cmpr0 <= din;
                    end
                    if(r_en) begin
                        dout <= cmpr0;
                    end
                end
                CMPR1_ADDRESS: begin
                    if(w_en) begin
                        cmpr1 <= din;
                    end
                    if(r_en) begin
                        dout <= cmpr1;
                    end
                end
                COUNTER_ADDRESS: begin
                    if(r_en) begin
                        dout <= counter;
                    end
                end
                default begin
                    dout <= 0;
                end
            endcase
        end
    end
    //*********************************************************************************************
endmodule