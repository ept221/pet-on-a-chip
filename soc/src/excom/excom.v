module excom(input wire clk,
			 input wire [7:0] din,
			 input wire [7:0] address,
			 input wire w_en,
			 input wire r_en,
			 output reg [7:0] dout,
			 input wire excom
);

	//***************************************************************
	parameter EXCOM_CONTROLLER_ADDRESS = 8'h00;
	localparam EXCOM_ADDRESS = EXCOM_CONTROLLER_ADDRESS;
	//***************************************************************
	reg [7:0] excom_reg = 0;
	always @(posedge clk) begin
		case(address)
			EXCOM_ADDRESS: begin
				if(r_en) begin
					dout <= excom_reg;
				end
			end
			default begin
                dout <= 0;
            end
		endcase 
	end
	//***************************************************************
	// generates a pulse every 0.2 seconds 
	reg [21:0] prescaler;
	reg scaled;
	always @(posedge clk) begin
		if(prescaler == 22'h30d400) begin
			prescaler <= 0;
			scaled <= 1;
		end
		else begin
			prescaler <= prescaler + 7'd1;
			scaled <= 0;
		end
	end
	//***************************************************************
	reg [1:0] sync = 2'b0;
	always @(posedge clk) begin
		sync[0] <= excom;
		sync[1] <= sync[0];
	end
	//***************************************************************
	reg delay = 0;
	reg [7:0] excom_counter = 0;
	always @(posedge clk) begin
		delay <= sync[1];
		if(scaled) begin
			excom_counter <= 0;
			excom_reg <= excom_counter;
		end
		else if(sync[1] && ~delay) begin
			excom_counter <= excom_counter + 12'b1;
		end
	end
	//***************************************************************
endmodule