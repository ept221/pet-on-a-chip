module test_tb();

	initial begin
		$dumpfile("test_tb.vcd");
		$dumpvars(0, my_cpu,d_ram_and_io_inst);

		#1000
			
		$finish;
	end

	reg clk = 0;

    always begin
			#1 clk <= ~clk;
	end

    //***************************************************************
    // Instantiate CPU
    //***************************************************************
    // Instantiate Instruction Memory
    wire iMemReadEnable;
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    
    //***************************************************************
    // Instantiate Interface to Data Memory and IO  

    wire top_flag;
    wire match0_flag;
    wire match1_flag;
    wire top_flag_clr;
    wire match0_flag_clr;
    wire match1_flag_clr;
    wire blanking_start_interrupt_flag;
    wire blanking_start_interrupt_flag_clr;
    wire [15:0] dMemIOAddress;
    wire [7:0] dMemIOOut;
    wire [7:0] dMemIOIn;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;
    wire [7:0] gpio_pins;

    i_ram instructionMemory(.din(16'd0),
                            .w_addr(12'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress[11:0]),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );

    cpu my_cpu(.clk(clk),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),
               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn),
               .interrupt_0(blanking_start_interrupt_flag),
               .interrupt_1(top_flag),
               .interrupt_2(match0_flag),
               .interrupt_3(match1_flag),
               .interrupt_0_clr(blanking_start_interrupt_flag_clr),
               .interrupt_1_clr(top_flag_clr),
               .interrupt_2_clr(match0_flag_clr),
               .interrupt_3_clr(match1_flag_clr)
    );

    d_ram_and_io d_ram_and_io_inst(.clk(clk),
                                   .din(dMemIOIn),
                                   .address(dMemIOAddress),
                                   .w_en(dMemIOWriteEn),
                                   .r_en(dMemIOReadEn),
                                   .dout(dMemIOOut),

                                   .gpio_pins(gpio_pins),

                                   .top_flag(top_flag),
                                   .match0_flag(match0_flag),
                                   .match1_flag(match1_flag),
                                   .top_flag_clr(top_flag_clr),
                                   .match0_flag_clr(match0_flag_clr),
                                   .match1_flag_clr(match1_flag_clr),

                                   .rx(rx),
                                   .tx(tx),

                                   .h_sync(),
                                   .v_sync(),
                                   .R(),
                                   .G(),
                                   .B(),
                                   .blanking_start_interrupt_flag(),
                                   .blanking_start_interrupt_flag_clr()
    );

    //***************************************************************

endmodule