module motor_controller(input wire clk,
						input wire [7:0] din,
						input wire [7:0] address,
						input wire w_en,
						input wire r_en,
						output reg [7:0] dout,

						input wire [1:0] encoders,
						output reg [1:0] pwm,
						output reg [3:0] motor,
						output reg enable
);
	parameter F_CPU = 16000000;
	//***************************************************************
	parameter MOTOR_CONTROLLER_ADDRESS = 8'h00;
	localparam MOTOR_ADDRESS = MOTOR_CONTROLLER_ADDRESS;
	localparam ENABLE_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 1;
	localparam SPEED_0_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 2;
	localparam SPEED_1_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 3;
	localparam RPM_0_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 4;
	localparam RPM_1_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 5;
	//***************************************************************
	always @(posedge clk) begin
		case(address)
			MOTOR_ADDRESS: begin
				if(w_en) begin
					motor <= din[3:0];
				end
				if(r_en) begin
					dout <= {4'b0,motor};
				end
			end
			ENABLE_ADDRESS: begin
				if(w_en) begin
					enable <= din[0];
				end
				if(r_en) begin
					dout <= {7'b0,enable};
				end
			end
			SPEED_0_ADDRESS: begin
				if(w_en) begin
					speed_0 <= {1'b0,din[6:0]};
				end
				if(r_en) begin
					dout <= cmpr0;
				end
			end
			SPEED_1_ADDRESS: begin
				if(w_en) begin
					speed_1 <= {1'b0,din[6:0]};
				end
				if(r_en) begin
					dout <= cmpr1;
				end
			end
			RPM_0_ADDRESS: begin
				if(r_en) begin
					dout <= rpm_0;
				end
			end
			RPM_1_ADDRESS: begin
				if(r_en) begin
					dout <= rpm_1;
				end
			end
			default begin
                dout <= 0;
            end
		endcase 
	end
	//***************************************************************
	// PWM
	reg [15:0] prescaler;
	reg scaled;
	localparam SCALE_FACTOR = 16'd125;
	always @(posedge clk) begin
		if(prescaler == SCALE_FACTOR) begin
			scaled <= 1;
			prescaler <= 0;
		end
		else begin
			scaled <= 0;
			prescaler <= prescaler + 1;
		end
	end

	reg [7:0] pwm_counter;
	reg [7:0] cmpr0;
	reg [7:0] cmpr1;
	always @(posedge clk) begin
		if(scaled) begin
			if(pwm_counter == 8'd255) begin         // If finished 256 cycles
                    pwm[0] <= 1;                    // On next edge (start of zero), set the outputs to 1
                    pwm[1] <= 1;
            end
            else begin
                if(pwm_counter == cmpr0) begin     // On match
                	pwm[0] <= 0;                   // clear pwm[0]
                end
                if(pwm_counter == cmpr1) begin     // On match
                	pwm[1] <= 0;                   // clear pwm[1]
                end
            end
            pwm_counter <= pwm_counter + 1;
		end
	end
	//***************************************************************
	// Encoders, RPM Calculation, and Integral Speed Control

	// The encoders have 10 poles, so there are 10 edges per 
	// encoder revolution. The gear ratio is 195.3:1, so there are 
	// 1953 edges per revolution of the wheel. 
	//
	// Our sample window time is 0.1 seconds, so the wheel's RPM can
	// be calulated by:
	// RPM = n*((60*revolution/(1953*encoder_counts))/(0.1 seconds)),
	// where n is the number of encoder counts measured in the 0.1
	// second interval.
	//
	// This reduces to n*(60/195.3) or approximately n*0.3072197.
	// We can write this in binary as n*0.010011101 but this is actually 
	// 0.306640625 in decimal.
	//
	// The quantazation noise is given by 60/195.3 or about 0.3072197 RPM.
	//
	// The maximum speed of the motor is 70 RPM, which corresponds to
	// about n = 227.85. Computing 227.85*(0.3072197 - 0.306640625) gives
	// approximately 0.1319. Thus the rounding gives a maximum error of
	// about 0.1319 RPM.
	//
	// So the maximum error should be about 0.3072 + 0.1319, or
	// 0.4391 RPM. Thus it only makes sense to report the integer portion
	// of the RPM calculation to the user.

	// Synchronizers to prevent metastability and brings the 
	// asynchronous encoder pulses into the clock domain
	reg [1:0] d0 = 0;
	reg [1:0] d1 = 0;
	always @(posedge clk) begin
		d0 <= encoders;
		d1 <= d0;
	end

	// These hold the target RPM values. These are 8-bit signed numbers,
	// but will always be positive. 
	reg [7:0] speed_0 = 0;
	reg [7:0] speed_1 = 0;

	// These hold the number of encoder counts in the 0.1 second window
	reg [7:0] encoder_count_0 = 0;
	reg [7:0] encoder_count_1 = 0;

	// These hold the measured RPM values in fixed point.
	// The upper 7-bits are the integer portion, and the lower
	// 9 bits are the fractional portion
	wire [15:0] full_rpm_0 = encoder_count_0*157;
	wire [15:0] full_rpm_1 = encoder_count_1*157;

	// These hold the measured RPM values, and are updated every 0.1
	// seconds. The MSB is always zero, and the 7 LSBs are from
	// the integer portion of the full_rpm registers. These are
	// 8-bit signed numbers, but will always be positive.
	reg [7:0] rpm_0 = 0;
	reg [7:0] rpm_1 = 0;

	// These hold the difference between the target speed, and
	// the measured RPM. These are 8-bit signed numbers.
	wire [7:0] error_0 = speed_0 - rpm_0;
	wire [7:0] error_1 = speed_1 - rpm_1;

	// These hold the next values of the PWM compare match registers.
	// Checking is done for overflow/underflow in the always block. 
	// These are 9 bit signed numbers.
	wire [8:0] next_0 = {1'b0,cmpr0} + {{1{error_0[7]}},error_0};
	wire [8:0] next_1 = {1'b0,cmpr1} + {{1{error_1[7]}},error_1};

	// Used to detect encoder pulse edges
	reg [1:0] edge_delay = 0;

	always @(posedge clk) begin
		edge_delay <= d1;
		if(strobe) begin
			rpm_0 <= {1'b0,full_rpm_0[15:9]};
			rpm_1 <= {1'b0,full_rpm_1[15:9]};
			encoder_count_0 <= 0;
			encoder_count_1 <= 0;
			if(~next_0[8]) begin
				cmpr0 <= next_0[7:0];
			end
			else begin
				cmpr0 <= {8{~error_0[7]}};
			end
			if(~next_1[8]) begin
				cmpr1 <= next_1[7:0];
			end
			else begin
				cmpr1 <= {8{~error_1[7]}};
			end
		end
		else begin
			if(edge_delay[0] ^ d1[0]) begin
				encoder_count_0 <= encoder_count_0 + 1;
			end
			if(edge_delay[1] ^ d1[1]) begin
				encoder_count_1 <= encoder_count_1 + 1;
			end
		end
	end
	//***************************************************************
	// Sample window generation. Strobe asserts every 0.1 seconds
	// for a single clock cycle
	
	localparam WIDTH = $clog2(F_CPU/10);

	wire [WIDTH:0] strobe_scale_factor = F_CPU/10;

	reg [WIDTH:0] x = 0;
	reg strobe = 0;
	always @(posedge clk) begin
		if(x == strobe_scale_factor) begin
			x <= 0;
			strobe <= 1;
		end
		else begin
			x <= x + 1;
			strobe <= 0;
		end
	end
	//***************************************************************
endmodule