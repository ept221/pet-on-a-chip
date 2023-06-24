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
    // The clock clk runs at 16Mhz
    // The servo angle will be controlled by an 8-bit number

    // 2200µs - 580µs = 1620µs                  ; 1620µs between min and max angle
    // 1620µs / 255 = 6.35µs                    ; 255 steps, 6.33µs per step
    // 1/16000000*x = 6.35 ==> x = 102          ; use a prescaler of 102 to get a tick every 6.35µs
    
    // (1/f)*x = 6.35us ==> x = 6.35*f

    parameter CLK_FREQ = 16000000;
    localparam SCALE_FACTOR = $rtoi($ceil(0.00000635*CLK_FREQ));
    localparam WIDTH = $clog2(SCALE_FACTOR);
    wire [WIDTH:0] scale_factor = SCALE_FACTOR;

    reg [WIDTH:0] prescaler;
    reg scaled;
    always @(posedge clk) begin
        if(prescaler == scale_factor) begin
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
    // 6.35µs*y = 20ms ==> y = 3150
    reg [11:0] counter;
    always @(posedge clk) begin
        if(scaled) begin
            if(counter == 12'd3150) begin
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    //***************************************************************
    // 6.35µs*z = 580µs ==> z = 91
    always @(posedge clk) begin
        servo_pin <= (counter < (12'd91 + servo));
    end
    //***************************************************************
endmodule