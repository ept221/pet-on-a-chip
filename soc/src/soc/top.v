module top(input wire clk,
           input wire reset,
           inout wire [7:0] gpio_pins,
           input wire rx,
           output wire tx,
           output wire [1:0] pwm,
           output wire [3:0] motor,
           output wire motor_enable,
           input wire [1:0] encoders,
           output wire h_sync,
           output wire v_sync,
           output wire R,
           output wire G,
           output wire B,
           output wire servo_pin,
           output wire trig,
           input wire echo
);
    parameter F_CPU = 16000000;
    //***************************************************************
    // Instantiate CPU
    wire reset_out;
    cpu my_cpu(.clk(clk),
               .reset(reset),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),
               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn),
               .interrupt(interrupt),
               .intVect(intVect),
               .intAck(intAck),
               .reset_out(reset_out)
    );
    //***************************************************************
    // Instantiate Instruction Memory
    wire iMemReadEnable;
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    i_ram instructionMemory(.din(16'd0),
                            .w_addr(12'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress[11:0]),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );
    //***************************************************************
    // Instantiate Interface to Data Memory and IO  
    wire [15:0] dMemIOAddress;
    wire [7:0] dMemIOOut;
    wire [7:0] dMemIOIn;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;

    wire interrupt;
    wire [15:0] intVect;
    wire intAck;

    d_ram_and_io d_ram_and_io_inst(.clk(clk),
                                   .rst(reset_out),
                                   .din(dMemIOIn),
                                   .address(dMemIOAddress),
                                   .w_en(dMemIOWriteEn),
                                   .r_en(dMemIOReadEn),
                                   .dout(dMemIOOut),

                                   .gpio_pins(gpio_pins),

                                   .rx(rx),
                                   .tx(tx),

                                   .pwm(pwm),
                                   .motor(motor),
                                   .motor_enable(motor_enable),
                                   .encoders(encoders),

                                   .servo_pin(servo_pin),

                                   .trig(trig),
                                   .echo(echo),

                                   .interrupt(interrupt),
                                   .intVect(intVect),
                                   .intAck(intAck),

                                   .h_sync(h_sync),
                                   .v_sync(v_sync),
                                   .R(R),
                                   .G(G),
                                   .B(B)
    );
    defparam d_ram_and_io_inst.F_CPU = 16000000;
    //***************************************************************
endmodule