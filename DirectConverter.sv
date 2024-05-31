

module DirectConverter(clk, adclk, daclk, ad, da);

    input clk;
    input [7:0] ad;
    output logic [7:0] da;
    output logic       adclk, daclk;


    logic clk_32, locked, reset;
    // input clk 125 MHz
    // clkout0 should be 32MHz
  clk_wiz_0 clk32_pll
   (
    // Clock out ports
    .clk_out1(clk_32),     // output clk_out1
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk)      // input clk_in1
);

    always_ff @(posedge clk_32) begin
        da <= ad;
    end

    always_comb begin
        adclk = clk_32;
        daclk = clk_32;
        reset = 0;
    end

endmodule // DirectConverter
