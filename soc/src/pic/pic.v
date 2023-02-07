module pic(input wire clk,
           input wire reset,
           input wire [7:0] din,
           input wire [7:0] address,
           input wire w_en,
           input wire r_en,
           output reg [7:0] dout,

           // To the cpu
           output reg interrupt,
           output reg [15:0] intVect,

           // From the cpu
           input wire intAck,

           // From peripherals
           input wire irq_0,
           input wire irq_1,
           input wire irq_2,
           input wire irq_3,
);
    //**********************************************************
    parameter PIC_ADDRESS = 8'h00;
    localparam VECT_0L = PIC_ADDRESS;
    localparam VECT_0H = PIC_ADDRESS + 1;
    localparam VECT_1L = PIC_ADDRESS + 2;
    localparam VECT_1H = PIC_ADDRESS + 3;
    localparam VECT_2L = PIC_ADDRESS + 4;
    localparam VECT_2H = PIC_ADDRESS + 5;
    localparam VECT_3L = PIC_ADDRESS + 6;
    localparam VECT_3H = PIC_ADDRESS + 7;
    //**********************************************************
    reg [7:0] vect_0l;
    reg [7:0] vect_0h;
    reg [7:0] vect_1l;
    reg [7:0] vect_1h;
    reg [7:0] vect_2l;
    reg [7:0] vect_2h;
    reg [7:0] vect_3l;
    reg [7:0] vect_3h;
    always @(posedge clk) begin
        case(address)
            VECT_0L: begin
                if(w_en) begin
                    vect_0l <= din;
                end
                if(r_en) begin
                    dout <= vect_0l;
                end
            end
            VECT_0H: begin
                if(w_en) begin
                    vect_0h <= din;
                end
                if(r_en) begin
                    dout <= vect_0h;
                end
            end
            VECT_1L: begin
                if(w_en) begin
                    vect_1l <= din;
                end
                if(r_en) begin
                    dout <= vect_1l;
                end
            end
            VECT_1H: begin
                if(w_en) begin
                    vect_1h <= din;
                end
                if(r_en) begin
                    dout <= vect_1h;
                end
            end
            VECT_2L: begin
                if(w_en) begin
                    vect_2l <= din;
                end
                if(r_en) begin
                    dout <= vect_2l;
                end
            end
            VECT_2H: begin
                if(w_en) begin
                    vect_2h <= din;
                end
                if(r_en) begin
                    dout <= vect_2h;
                end
            end
            VECT_3L: begin
                if(w_en) begin
                    vect_3l <= din;
                end
                if(r_en) begin
                    dout <= vect_3l;
                end
            end
            VECT_3H: begin
                if(w_en) begin
                    vect_3h <= din;
                end
                if(r_en) begin
                    dout <= vect_3h;
                end
            end
            default begin
                dout <= 8'b0;
            end
        endcase
    end
    //**********************************************************
    // Latches incoming irqs into the pending register, and also
    // clears the pending bit corresponding to the current irq
    // if the intAck signal from the CPU is asserted. Also ff an
    // interrupt is not in progress, start the one pending that
    // has the highest priority, or the incoming irq with the
    // highest priority.
    reg [3:0] pending;
    reg [2:0] current;
    reg in_progress = 1'b0;
    always @(posedge clk) begin
        //******************************************************
        if(irq_0 == 1'b1) begin
            pending[0] <= 1'b1;
        end
        else if(intAck == 1'b1 && current == 2'd0) begin
            pending[0] <= 1'b0;
        end
        //******************************************************
        if(irq_1 == 1'b1) begin
            pending[1] <= 1'b1;
        end
        else if(intAck == 1'b1 && current == 2'd1) begin
            pending[1] <= 1'b0;
        end
        //******************************************************
        if(irq_2 == 1'b1) begin
            pending[2] <= 1'b1;
        end
        else if(intAck == 1'b1 && current == 2'd2) begin
            pending[2] <= 1'b0;
        end
        //******************************************************
        if(irq_3 == 1'b1) begin
            pending[3] <= 1'b1;
        end
        else if(intAck == 1'b1 && current == 2'd3) begin
            pending[3] <= 1'b0;
        end
        //******************************************************
        if(irq_0 == 1'b1 || pending[0] == 1'b1 && in_progress == 1'b0) begin
            in_progress <= 1'b1;
            current <= 2'd0;
        end
        else if(irq_1 == 1'b1 || pending[1] == 1'b1 && in_progress == 1'b0) begin
           in_progress <= 1'b1;
           current <= 2'd1;
        end
        else if(irq_2 == 1'b1 || pending[2] == 1'b1 && in_progress == 1'b0) begin
            in_progress <= 1'b1;
            current <= 2'd2;
        end
        else if(irq_3 == 1'b1 || pending[3] == 1'b1 && in_progress == 1'b0) begin
            in_progress <= 1'b1;
            current <= 2'd3;
        end
    end
    //**********************************************************
    // Signals the CPU with the current interrupt of
    // the highest priority
    always @(*) begin
        if(current == 2'd0 && pending[0] == 1'b1) begin
            interrupt = 1'b1;
            intVect = {vect_0h,vect_0l};
        end
        else if(current == 2'd1 && pending[1] == 1'b1) begin
            interrupt = 1'b1;
            intVect = {vect_1h,vect_1l};
        end
        else if(current == 2'd2 && pending[2] == 1'b1) begin
            interrupt = 1'b1;
            intVect = {vect_2h,vect_2l};
        end
        else if(current == 2'd3 && pending[3] == 1'b1) begin
            interrupt = 1'b1;
            intVect = {vect_3h,vect_3l};
        end
        else begin
            interrupt = 1'b0;
            intVect = {vect_0h,vect_0l};
        end
    end
    //**********************************************************
endmodule
