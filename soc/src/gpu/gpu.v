module gpu(input wire clk,
           input wire rst,
           input wire [7:0] din,
           input wire [15:0] address,
           input wire w_en,
           input wire r_en,
           input wire vram_w_en,
           output reg [7:0] dout,

           output reg h_syncD2,
           output reg v_syncD2,
           output wire R,
           output wire G,
           output wire B,

           output wire blanking_start_interrupt_flag
);

    parameter GPU_IO_ADDRESS = 8'h00;
    parameter GPU_VRAM_ADDRESS = 16'h2000;
    localparam GPU_CONTROL_ADDRESS = GPU_IO_ADDRESS;

    //*****************************************************************************************************************
    // Create the VGA clock with the PLL
    wire vgaClk;
    wire locked;
    pll vgaClkGen(.clock_in(clk),.clock_out(vgaClk),.locked(locked));
    
    //*****************************************************************************************************************
    // Create the sync generator 
    wire [9:0] x, y;
    wire h_sync, v_sync, active, blanking_start;
    vga syncGen(.clk(vgaClk),.h_sync(h_sync),.v_sync(v_sync), .active(active), .blanking_start(blanking_start), .x(x), .y(y));

    //*****************************************************************************************************************
    // The RAM and ROM modules each introduce one clock cycle of delay, so
    // in order for everything to be in sync, we need to produce delayed
    // versions of the control signals from the sync generator.
    reg [9:0] xD1, xD2, yD1;
    reg h_syncD1, v_syncD1, activeD1, activeD2, blanking_startD1, blanking_startD2;
    always @(posedge vgaClk) begin
        xD1 <= x;
        xD2 <= xD1;

        yD1 <= y;

        h_syncD1 <= h_sync;
        h_syncD2 <= h_syncD1;

        v_syncD1 <= v_sync;
        v_syncD2 <= v_syncD1;

        activeD1 <= active;
        activeD2 <= activeD1;

        blanking_startD1 <= blanking_start;
        blanking_startD2 <= blanking_startD1;
    end

    //*****************************************************************************************************************
    //                                              gpu_control_register
    //
    // *--------*--------*--------*--------*--------*--------*----------------------------*--------------------------*
    // |PLL lock|  N/A   |  N/A   |  blue  | green  |  red   | frame_end_interrupt_enable | frame_end_interrupt_flag |
    // *--------*--------*--------*--------*--------*--------*----------------------------*--------------------------*
    //     7        6        5        4        3        2                  1                           0 
    //*****************************************************************************************************************

    reg red = 1;
    reg green = 1;
    reg blue = 1;

    reg l0 = 0;
    reg l1 = 0;
    always @(posedge clk) begin
        l0 <= locked;
        l1 <= l0;
        if(rst) begin
            {blue, green, red} <= 0;
            blanking_start_interrupt_enable <= 0;
            dout <= 0;
        end
        else if(address[7:0] == GPU_CONTROL_ADDRESS && w_en) begin
            {blue, green, red} <= din[4:2];
            blanking_start_interrupt_enable <= din[1];
        end
        else if(address[7:0] == GPU_CONTROL_ADDRESS && r_en) begin
            dout[1:0] <= {blanking_start_interrupt_enable,blanking_start_interrupt_flag};
            dout[4:2] <= {blue, green, red};
            dout[6:5] <= 0;
            dout[7] <= l1;
        end
        else begin
            dout <= 0;
        end
    end

    //*****************************************************************************************************************
    // Interrupt Control
    //
    // This is tricky, because we need to pass the end of frame signal from
    // the vgaClk domain to the clk clock domain.

    // flag_vgaClk is a flip-flop in the vglClk domain and is set whenever
    // there is an end of frame. It is reset if it receives
    // the acknowledge signal
    reg flag_vgaClk = 0;
    always @(posedge vgaClk) begin
        if(blanking_startD2 && ~acknowledge) begin
            flag_vgaClk <= 1;
        end
        else if(acknowledge) begin
            flag_vgaClk <= 0;
        end
    end

    // sync_to_clk is a pair of flip-flops in the clk domain which synchronizes
    // the flag_vgaClk flip-flop from the vgaClk domain to the clk domain
    reg [1:0] sync_to_clk = 0;
    always @(posedge clk) begin
        sync_to_clk <= {sync_to_clk[0],flag_vgaClk};
    end

    // sync_to_vgaClk is a pair of flip-flops in the vgaClk domain which synchronizes
    // the recived flag in the clk domain back into the vgaClk domain as the
    // acknowledge signal
    reg [1:0] sync_to_vgaClk = 0;
    always @(posedge vgaClk) begin
        sync_to_vgaClk <= {sync_to_vgaClk[0],&sync_to_clk};
    end

    wire acknowledge = sync_to_vgaClk[1];

    // edgeFlop is a flip-flop in the clk domain which is used to detect the edge
    // of the incoming flag when it is brought into the clk domain
    reg edgeFlop = 0;
    always @(posedge clk) begin
        edgeFlop <= &sync_to_clk; 
    end

    reg blanking_start_interrupt_enable = 0;
    assign blanking_start_interrupt_flag = &sync_to_clk && ~edgeFlop && blanking_start_interrupt_enable;
    //*****************************************************************************************************************
    // Create the text RAM addressed by the current tile being displayed
    // by the vga sync generator.
    reg [7:0] char;
    wire [11:0] current_char_address = ({5'b0,x[9:3]} + (y[9:4]*80));
    wire readRamActive = (current_char_address < 12'd2400) ? 1 : 0;
    wire writeRamActive = (address >= GPU_VRAM_ADDRESS && address <= GPU_VRAM_ADDRESS + 16'd2399);
    ram myRam(
              .din(din),
              .w_addr(address[11:0]),
              .w_en(vram_w_en && writeRamActive),
              .r_addr(current_char_address),
              .r_en(readRamActive),
              .w_clk(clk),
              .r_clk(vgaClk),
              .dout(char)
    );

    //*****************************************************************************************************************
    // Create the font ROM. The upper portion of the address comes from the 
    // output of the text RAM, which then has 32 subtracted from it, to
    // account for the ASCII code, which, which then gives the start of a
    // particular char, and the lower portion of the address comes from the 
    // row number output from the sync generator. The output pixelRow give
    // a single horizontal slice of a particular glyph.
    wire [7:0] pixelRow;
    wire [7:0] upper = char - 8'd32;
    rom myRom(8'd0,{upper[6:0],yD1[3:0]},1'd0,vgaClk,pixelRow);

    // We need to reverse the order of pixelRow to make it easy to index into
    // because the LSB is the rightmost pixel, but we need it to be the left
    // most pixel, because we display pixels from left to right.
    genvar i;
    wire [7:0] reversedPixleRow;
    for(i = 0; i < 8; i++) begin
        assign reversedPixleRow[i] = pixelRow[7-i];
    end
    wire pixel = reversedPixleRow[xD2[2:0]];

    assign R = activeD2 && pixel && red;
    assign G = activeD2 && pixel && green;
    assign B = activeD2 && pixel && blue;

endmodule

//*********************************************************************************************************************
// ASCII char RAM
module ram(din, w_addr, w_en, r_addr, r_en, r_clk, w_clk, dout);
    initial begin
        $readmemh("soc/src/gpu/ram.hex",mem);
    end

    parameter addr_width = 12;
    parameter data_width = 8;
    input [addr_width-1:0] w_addr;
    input [addr_width-1:0] r_addr;
    input [data_width-1:0] din;
    input w_en, r_en, r_clk, w_clk;
    output [data_width-1:0] dout;
    reg [data_width-1:0] dout;
    reg [data_width-1:0] mem [0:2399];

    always @(posedge w_clk) begin
        if(w_en) begin
            mem[w_addr] <= din;
        end
    end

    always @(posedge r_clk) begin
        if(r_en) begin
            dout <= mem[r_addr];
        end
    end

endmodule

//*********************************************************************************************************************
// Font ROM
module rom(din, addr, write_en, clk, dout);
    initial begin
        $readmemh("soc/src/gpu/rom.hex",mem);
    end

    parameter addr_width = 11;
    parameter data_width = 8;
    input [addr_width-1:0] addr;
    input [data_width-1:0] din;
    input write_en, clk;
    output [data_width-1:0] dout;
    reg [data_width-1:0] dout;
    reg [data_width-1:0] mem [0:(1<<addr_width)-1];

    always @ (posedge clk)
    begin
        if(write_en)
            mem[addr] <= din;
        dout <= mem[addr];
    end

endmodule