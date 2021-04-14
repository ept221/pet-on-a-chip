module counter_timer(input wire clk,
                     input wire [7:0] din,
                     input wire [7:0] address,
                     input wire w_en,
                     input wire r_en,
                     output reg [7:0] dout,
                     output reg out0 = 0,
                     output reg out1 = 0,
                     output wire out0_en,
                     output wire out1_en,
                     output reg top_flag = 0,
                     output reg match0_flag = 0,
                     output reg match1_flag = 0,
                     input wire top_flag_clr,
                     input wire match0_flag_clr,
                     input wire match1_flag_clr
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
        if(prescaler == scaleFactor) begin
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
        if(scaled) begin
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
        // Needed to detect edges
        top_old <= top;
        match0_old <= match0;
        match1_old <= match1;

        // Top
        if(top_flag_clr) begin
            top_flag <= 0;
        end
        else if(address == INTERRUPT_FLAGS_ADDRESS && w_en) begin        // Interrupt flag register
            top_flag <= din[0];
        end
        else if(top && (~top_old) && counterControl[4]) begin
            top_flag <= 1;
        end

        // Match0
        if(match0_flag_clr) begin
            match0_flag <= 0;
        end
        else if(address == INTERRUPT_FLAGS_ADDRESS && w_en) begin        // Interrupt flag register
            match0_flag <= din[1];
        end
        else if(match0 && (~match0_old) && counterControl[5]) begin
            match0_flag <= 1;
        end

        // Match1
        if(match1_flag_clr) begin
            match1_flag <= 0;
        end
        else if(address == INTERRUPT_FLAGS_ADDRESS && w_en) begin        // Interrupt flag register
            match1_flag <= din[2];
        end
        else if(match1 && (~match1_old) && counterControl[6]) begin
            match1_flag <= 1;
        end
    end
    //*********************************************************************************************
    always @(posedge clk) begin
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
    //*********************************************************************************************
endmodule