module servo(input wire clk,
			 input wire [7:0] din,
			 input wire [7:0] address,
			 input wire w_en,
			 input wire r_en,
			 output reg [7:0] dout,
			 output reg servo_pin
);

	//***************************************************************
	parameter SERVO_CONTROLLER_ADDRESS = 8'h00;
	localparam SERVO_ADDRESS = SERVO_CONTROLLER_ADDRESS;
	//***************************************************************
	reg [7:0] servo;
	always @(posedge clk) begin
		case(address)
			SERVO_ADDRESS: begin
				if(w_en) begin
					servo <= din;
				end
				if(r_en) begin
					dout <= servo;
				end
			end
			default begin
                dout <= 0;
            end
		endcase 
	end
	//***************************************************************
	reg [7:0] prescaler;
	reg scaled;
	always @(posedge clk) begin
		if(prescaler == 7'd94) begin
			prescaler <= 0;
			scaled <= 1;
		end
		else begin
			prescaler <= prescaler + 7'd1;
			scaled <= 0;
		end
	end
	//***************************************************************
	reg [11:0] counter;
	always @(posedge clk) begin
		if(scaled) begin
			if(counter == 12'd3404) begin
				counter <= 0;
			end
			else begin
				counter <= counter + 1;
			end
		end
	end
	//***************************************************************
	always @(posedge clk) begin
		servo_pin <= (counter < (12'd110 + servo));
	end
	//***************************************************************
endmodule