
`timescale 1ns/10ps
`default_nettype none

module basic_nco_tb;
    parameter CLK_FREQ = 256_000_000;
    parameter CLK_PERIOD = 1000000000.0/CLK_FREQ;
    parameter ACC_W = 32;
    parameter PHASE_W = 18;
    parameter PHASE_POINT = 16;
    parameter COARSE_ADDR_W = 9;

    parameter NCO_FREQ = 1_000_00;

    localparam ratio = real'(NCO_FREQ) / real'(CLK_FREQ);
    parameter TUNE = int'((2.0**32) * ratio);

    /*AUTOWIRE*/
    // Beginning of automatic wires (for undeclared instantiated-module outputs)
    logic [PHASE_W-1:0] o_phase;                // From DUT of basic_nco.v
    // End of automatics

    /*AUTOREG*/

    /*AUTOREGINPUT*/
    // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
    reg                 ce;                     // To DUT of basic_nco.v
    reg                 clk;                    // To DUT of basic_nco.v
    reg [ACC_W-1:0]     i_tune;                 // To DUT of basic_nco.v
    reg                 reset;                  // To DUT of basic_nco.v
    // End of automatics

    basic_nco #(/*AUTOINSTPARAM*/
                // Parameters
                .ACC_W                  (ACC_W),
                .PHASE_W                (PHASE_W),
                .PHASE_POINT            (PHASE_POINT),
                .COARSE_ADDR_W          (COARSE_ADDR_W)) DUT (/*AUTOINST*/
                                                              // Outputs
                                                              .o_phase          (o_phase[PHASE_W-1:0]),
                                                              // Inputs
                                                              .clk              (clk),
                                                              .ce               (ce),
                                                              .reset            (reset),
                                                              .i_tune           (i_tune[ACC_W-1:0]));

    always begin
        #CLK_PERIOD;
        clk = ~clk;
    end


    initial begin
        clk   = 0;
        reset = 1;
        #50;
        reset  = 0;
        ce     = 1;
        i_tune = TUNE;

    end



endmodule // basic_nco_tb

// Local Variables:
// verilog-auto-inst-param-value: t
// End:
