module vga(input wire clk,
		   output wire h_sync,
		   output wire v_sync,
		   output wire active,
		   output wire blanking_start,
		   output reg [9:0] x,
		   output reg [9:0] y
);

	localparam H_ACTIVE = 640;
	localparam H_FP = 15;
	localparam H_SYNC = 96;
	localparam H_BP = 48;
	localparam HS_START = H_ACTIVE + H_FP - 1;
	localparam HS_END = H_ACTIVE + H_FP + H_SYNC - 1;
	localparam H_LINE = H_ACTIVE + H_FP + H_SYNC + H_BP;

	localparam V_ACTIVE = 480;
	localparam V_FP = 10;
	localparam V_SYNC = 2;
	localparam V_BP = 32;
	localparam VS_START = V_ACTIVE + V_FP - 1;
	localparam VS_END = VS_START + V_SYNC;
	localparam V_LINE = V_ACTIVE + V_FP + V_SYNC + V_BP;

	assign h_sync = ~((x >= HS_START) & (x <= HS_END));
	assign v_sync = ~((y >= VS_START) & (y <= VS_END));

	assign active = (x < H_ACTIVE && y < V_ACTIVE);
	assign blanking_start = (y == V_ACTIVE) && (x == 0);

	always @(posedge clk) begin

		if(x < H_LINE) begin
			x <= x + 10'd1;
		end
		else begin
			x <= 10'd0;
			if(y < V_LINE) begin
				y <= y + 10'd1;
			end
			else begin
				y <= 10'd0;
			end
		end
	end
	
endmodule