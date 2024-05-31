
`timescale 1ns/10ps
`default_nettype none

module basic_nco_tb;
    parameter CLK_FREQ = 32_000_000;
    parameter CLK_PERIOD = 1000000000.0/CLK_FREQ;
    parameter ACC_W = 32;
    parameter PHASE_W = 18;
    parameter PHASE_POINT = 16;
    parameter COARSE_ADDR_W = 9;

    parameter NCO_FREQ = 6_500_000;

    localparam ratio = real'(NCO_FREQ) / real'(CLK_FREQ);
    parameter TUNE = int'((2.0**32) * ratio);
    parameter TUNE2 = int'((2.0**25) * ratio);

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

    int                 fd, fo;
    logic signed [7:0]  samples, sample_q;

    initial begin
        fd = $fopen("../../../../samples.txt", "r");
        fo = $fopen("../../../../o_samples.txt", "w");
    end

    always_ff @(posedge clk) begin
        if ($fscanf(fd, "%d", samples) == 1)
            sample_q <= samples;
    end

    logic signed [13:0] sin, cos, sin1, cos1; // sfix14_12
    logic [31:0] overflow;
    logic out_valid;
    
    dds_compiler_0 DUT2 (
      .aclk(clk),                                // input wire aclk
      .s_axis_phase_tvalid(ce),  // input wire s_axis_phase_tvalid
      .s_axis_phase_tdata(TUNE2),    // input wire [31 : 0] s_axis_phase_tdata
      .m_axis_data_tvalid(out_valid),    // output wire m_axis_data_tvalid
      .m_axis_data_tdata(overflow)      // output wire [31 : 0] m_axis_data_tdata
    );

    logic [31:0] cmpy_b_in, cmpy_out;
    logic        out_valid_q;
    logic mix_valid;
    logic [(14+8)-1:0] m_out_i, m_out_q;
    logic signed [15:0] dc_i, dc_q;

    always_comb begin
        sin = overflow[31:16];
        cos = overflow[15:0];
    end

    always_ff @(posedge clk) begin

        cmpy_b_in[31:16] <= -sin;
        cmpy_b_in[15:0]  <= cos;
        out_valid_q      <= out_valid;
    end

    // mult_gen_0 mix_i (
    //   .CLK(clk),  // input wire CLK
    //   .A(sample_q),      // input wire [7 : 0] A
    //   .B(cos1),      // input wire [13 : 0] B
    //   .CE(out_valid),    // input wire CE
    //   .P(m_out_i)      // output wire [21 : 0] P
    // ), mix_q (
    //   .CLK(clk),  // input wire CLK
    //   .A(sample_q),      // input wire [7 : 0] A
    //   .B(sin1),      // input wire [13 : 0] B
    //   .CE(out_valid),
    //   .P(m_out_q)      // output wire [21 : 0] P
    // );



    cmpy_0 down_mix (
      .aclk(clk),                              // input wire aclk
      .s_axis_a_tvalid(out_valid_q),        // input wire s_axis_a_tvalid
      .s_axis_a_tdata({8'b0,sample_q}),          // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(out_valid_q),        // input wire s_axis_b_tvalid
      .s_axis_b_tdata(cmpy_b_in),          // input wire [31 : 0] s_axis_b_tdata
      .s_axis_ctrl_tdata(sample_q[0]),
      .s_axis_ctrl_tvalid(ce),
      .m_axis_dout_tvalid(mix_valid),  // output wire m_axis_dout_tvalid
      .m_axis_dout_tdata(cmpy_out)    // output wire [31 : 0] m_axis_dout_tdata
    );

    assign dc_q = cmpy_out[31:16];
    assign dc_i = cmpy_out[15:0];

    // logic cordic_valid;
    // logic [31:0] cordic_out;
    // logic signed [15:0] phase;

    // cordic_0 iq2pm (
    //   .aclk(clk),                                        // input wire aclk
    //   .aclken(ce),                                    // input wire aclken
    //   .s_axis_cartesian_tvalid(mix_valid),  // input wire s_axis_cartesian_tvalid
    //   .s_axis_cartesian_tdata({dc_i, dc_q}),    // input wire [31 : 0] s_axis_cartesian_tdata
    //   .m_axis_dout_tvalid(cordic_valid),            // output wire m_axis_dout_tvalid
    //   .m_axis_dout_tdata(cordic_out)              // output wire [31 : 0] m_axis_dout_tdata
    // );

    // assign phase = cordic_out[31:16];

    always_ff @(posedge clk) begin
        $fdisplay(fo, "%d, %d, %d, %d, %d", dc_i, dc_q, sample_q, cos, sin);
    end
    
    always begin
        #(CLK_PERIOD/2);
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
