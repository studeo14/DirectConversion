// Filename        : DirectConverter.sv
// Description     : Top module for DirectConversion receiver module
// Author          : Steven Frederiksen
// Created On      : Thu May 30 23:04:32 2024
// Last Modified By: Steven Frederiksen
// Last Modified On: Thu May 30 23:04:32 2024
// Update Count    : 0
// Status          : Unknown, Use with caution!

`default_nettype none

module DirectConverter (
    clk,
    adclk,
    daclk,
    ad,
    da
);
    parameter integer CLK_FREQ = 32_000_000;
    parameter real CLK_PERIOD = 1000000000.0 / CLK_FREQ;
    parameter integer ACC_W = 32;
    parameter integer PHASE_W = 18;
    parameter integer PHASE_POINT = 16;
    parameter integer COARSE_ADDR_W = 9;

    parameter integer NCO_FREQ = 6_500_000;

    localparam real RATIO = real'(NCO_FREQ) / real'(CLK_FREQ);
    parameter integer TUNE = int'((2.0 ** 32) * RATIO);
    parameter integer TUNE2 = int'((2.0 ** 25) * RATIO);

    input logic clk;
    input logic [7:0] ad;
    output logic [7:0] da;
    output logic adclk, daclk;

    logic clk_32, locked, reset;
    // input clk 125 MHz
    // clkout0 should be 32MHz
    clk_wiz_0 clk32_pll (
        // Clock out ports
        .clk_out1(clk_32),  // output clk_out1
        // Status and control signals
        .reset   (reset),   // input reset
        .locked  (locked),  // output locked
        // Clock in ports
        .clk_in1 (clk)      // input clk_in1
    );

    logic out_valid;
    logic [31:0] overflow;
    logic signed [13:0] sin, cos, sin1, cos1;
    logic [31:0] cmpy_b_in, cmpy_out;
    logic out_valid_q;
    logic mix_valid;
    logic [(14+8)-1:0] m_out_i, m_out_q;
    logic signed [15:0] dc_i, dc_q;

    dds_compiler_0 dds (
        .aclk               (clk_32),     // input wire aclk
        .s_axis_phase_tvalid(locked),         // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata (TUNE2),      // input wire [31 : 0] s_axis_phase_tdata
        .m_axis_data_tvalid (out_valid),  // output wire m_axis_data_tvalid
        .m_axis_data_tdata  (overflow)    // output wire [31 : 0] m_axis_data_tdata
    );

    always_comb begin
        sin = overflow[31:16];
        cos = overflow[15:0];
    end

    always_ff @(posedge clk_32) begin

        cmpy_b_in[31:16] <= -sin;
        cmpy_b_in[15:0]  <= cos;
        out_valid_q      <= out_valid;
    end

    cmpy_0 down_mix (
        .aclk              (clk_32),       // input wire aclk
        .s_axis_a_tvalid   (out_valid_q),  // input wire s_axis_a_tvalid
        .s_axis_a_tdata    ({8'b0, ad}),   // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid   (out_valid_q),  // input wire s_axis_b_tvalid
        .s_axis_b_tdata    (cmpy_b_in),    // input wire [31 : 0] s_axis_b_tdata
        .s_axis_ctrl_tdata (1),
        .s_axis_ctrl_tvalid(1),
        .m_axis_dout_tvalid(mix_valid),    // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata (cmpy_out)      // output wire [31 : 0] m_axis_dout_tdata
    );

    always_comb begin
        dc_q = cmpy_out[31:16];
        dc_i = cmpy_out[15:0];
    end

    // do some convergent rounding (even)
    logic signed [15:0] w_q, w_i;
    logic signed [7:0] o_q, o_i;

    always_comb begin
        w_q = dc_q + {{8{1'b0}}, dc_q[16-8], {(16 - 8 - 1) {!dc_q[16-8]}}};
        w_i = dc_i + {{8{1'b0}}, dc_i[16-8], {(16 - 8 - 1) {!dc_i[16-8]}}};
    end

    always_ff @(posedge clk_32) begin
        o_q <= w_q[15:(16-8)];
        o_i <= w_i[15:(16-8)];
    end

    always_ff @(posedge clk_32) begin
        da <= o_i;
    end

    always_comb begin
        adclk = clk_32;
        daclk = clk_32;
        reset = 0;
    end

endmodule : DirectConverter
