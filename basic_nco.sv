//                              -*- Mode: Verilog -*-
// Filename        : basic_nco.sv
// Description     : Basic NCO with internal init
// Author          : Steven Frederiksen
// Created On      : Wed Apr 17 21:59:18 2024
// Last Modified By: Steven Frederiksen
// Last Modified On: Wed Apr 17 21:59:18 2024
// Update Count    : 0
// Status          : Good avg error numbers. Can check by tweaking the parameters.
//                   - The pipelining is necessary for Vivado syntehsis to infer things correctly.
//						Even though there is the ROM style attr, the pipelines clean up the logic inference.

module basic_nco(clk, ce, reset, i_tune, o_phase);
    parameter ACC_W = 32;
    parameter PHASE_W = 18;
    parameter PHASE_POINT = 16;
    parameter COARSE_ADDR_W = 9;
    localparam COARSE_DEPTH = 2**COARSE_ADDR_W;
    localparam PI = 3.14;
    localparam STEP = (PI/2) / COARSE_DEPTH;

    input      clk, ce, reset;
    input [ACC_W-1:0] i_tune;
    output logic signed [PHASE_W-1:0] o_phase;

    typedef logic signed [PHASE_W-1:0] phase_table_t [COARSE_DEPTH];
    typedef logic signed [PHASE_W-1:0] phase_t;

    function phase_table_t init_nco_table(input real start, input real stop, input int N);
        real                           step = (stop - start) / real'(N);
        real                           temp;
        int                            ix;
        for (ix = 0; ix < N; ix = ix + 1) begin
            temp              = $sin(ix*step);
            init_nco_table[ix] = temp * (2**PHASE_POINT);
        end
    endfunction

    (* rom_style = "block" *)
    phase_table_t nco_table;
    (* rom_style = "block" *)
    phase_table_t frac_table;

    initial begin
        nco_table     = init_nco_table(0.0, PI/2.0, COARSE_DEPTH);
        frac_table    = init_nco_table(0.0, STEP, COARSE_DEPTH);
    end

    logic [ACC_W-1:0] phase_acc = 0;
    logic [3:0][1:0]  quad;
    logic [COARSE_ADDR_W-1:0] idx, f_idx;
    phase_t coarse, fine, c_n, f_n;

    `ifndef SYNTHESIS
    real              dut_out, real_out, real_phase, acc_err, err, avg_err;
    int               inters = 0;
    `endif

    always_ff @(posedge clk) begin
        if (reset) begin
            phase_acc <= 0;
            o_phase   <= 0;
        end else if (ce) begin
            // clk 1
            phase_acc <= phase_acc + i_tune;
            quad      <= {quad[2:0], phase_acc[ACC_W-1:ACC_W-2]};
            if (phase_acc[ACC_W-2])
                idx <= ~phase_acc[ACC_W-3-:COARSE_ADDR_W];
            else
                idx <= phase_acc[ACC_W-3-:COARSE_ADDR_W];
            f_idx   <= phase_acc[ACC_W-3-COARSE_ADDR_W-:COARSE_ADDR_W];

            // clk 2
            coarse  <= nco_table[idx];
            fine    <= frac_table[f_idx];

            // clk 3
            case(quad[1])
                2'b00: c_n <=  coarse;
                2'b01: c_n <=  coarse;
                2'b10: c_n <= -coarse;
                2'b11: c_n <= -coarse;
            endcase // case (quad)
            case(quad[1])
                2'b00: f_n <=  fine;
                2'b01: f_n <= -fine;
                2'b10: f_n <= -fine;
                2'b11: f_n <=  fine;
            endcase // case (quad)
            // clk 3
            o_phase    <= c_n + f_n;

            `ifndef SYNTHESIS
            dut_out     = real'(o_phase) / (2.0**PHASE_POINT);
            real_phase  = real'($past(phase_acc, 4)) / (2.0**ACC_W);
            real_out    = $sin(real_phase*2*PI);
            err         = $sqrt($pow(real_out - dut_out, 2));
            acc_err     = acc_err + err;
            avg_err     = acc_err/inters;
            inters      = inters + 1;
            `endif
        end
    end

endmodule
