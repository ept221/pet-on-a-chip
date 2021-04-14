// Does not handle pullups or pin type, but works
// for this project

module SB_IO(inout wire PACKAGE_PIN,
             input wire OUTPUT_ENABLE,
             input wire D_OUT_0,
             output wire D_IN_0
);
        parameter PIN_TYPE = 0;
        parameter PULLUP = 0;

        assign PACKAGE_PIN = (OUTPUT_ENABLE == 1) ? D_OUT_0 : 1'bz;
        assign D_IN_0 = PACKAGE_PIN;    
endmodule