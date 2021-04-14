module vga(input wire clk,
		   output wire h_sync,
		   output wire v_sync,
		   output wire active,
		   output wire blanking_start,
		   output reg [9:0] x,
		   output reg [9:0] y
);

	parameter HS_START = 640 + 15 - 1;
	parameter HS_END = 640 + 16 + 96 - 1;
	parameter VS_START = 480 + 10 - 1;
	parameter VS_END = 480 + 10 + 2 - 1;

	parameter HDISP_START = 0;
	parameter VDISP_START = 0;

	assign h_sync = ~((x >= HS_START) & (x < HS_END));
	assign v_sync = ~((y >= VS_START) & (y < VS_END));

	assign active = (x < 640 && y < 480);
	assign blanking_start = (y == 480) && (x == 0);

	always @(posedge clk) begin

		if(x < 799) begin
			x <= x + 10'd1;
		end
		else begin
			x <= 10'd0;
			if(y < 524) begin
				y <= y + 10'd1;
			end
			else begin
				y <= 10'd0;
			end
		end
	end
	
endmodule