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
	// The pulse width for the min angle on the servo is 580µs
	// The pulse width for the max angle on the servo is 2200µs
	// 2200µs - 580µs = 1620µs
	// 1620µs / 256 = 6.33µs
	// 1/16000000*x = 6.33 ==> x = 101
	reg [7:0] prescaler;
	reg scaled;
	always @(posedge clk) begin
		if(prescaler == 8'd101) begin
			prescaler <= 0;
			scaled <= 1;
		end
		else begin
			prescaler <= prescaler + 8'd1;
			scaled <= 0;
		end
	end
	//***************************************************************
	// Period of servo waveform is 20ms
	// 6.33µs*y = 20ms ==> y = 3160
	reg [11:0] counter;
	always @(posedge clk) begin
		if(scaled) begin
			if(counter == 12'd3160) begin
				counter <= 0;
			end
			else begin
				counter <= counter + 1;
			end
		end
	end
	//***************************************************************
	// 6.33µs*z = 580µs ==> z = 92
	always @(posedge clk) begin
		servo_pin <= (counter < (12'd92 + servo));
	end
	//***************************************************************
endmodule