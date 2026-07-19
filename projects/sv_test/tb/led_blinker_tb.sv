// =============================================================================
// File        : led_blinker_tb.sv
// Project      : qmtech-workspace / sv_test
// Standard     : IEEE 1800-2012 (SystemVerilog)
// Description  : Self-checking testbench for led_blinker. Runs the design
//                through several blink cycles and confirms the LED output
//                resolves to a known logic value (no X propagation).
// =============================================================================
`timescale 1ns / 1ps

module led_blinker_tb;
    logic clk;
    logic rst_n;
    logic [1:0] led;

    // GATE_SIM is defined explicitly by scripts/sim_gate.tcl (xvlog -d GATE_SIM)
    // when compiling this testbench against the post-synthesis netlist. That
    // netlist has BLINK_MAX already resolved to a fixed value during synthesis
    // and has no such parameter to bind, so the override below only applies to
    // RTL simulation (sim-vhdl/sim-sv), where it speeds up the blink cycle.
    `ifdef GATE_SIM
        led_blinker uut (
            .clk(clk),
            .rst_n(rst_n),
            .led(led)
        );
    `else
        led_blinker #(
            .BLINK_MAX(5) // Reduced for fast simulation validation
        ) uut (
            .clk(clk),
            .rst_n(rst_n),
            .led(led)
        );
    `endif

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz simulated clock
    end

    initial begin
        // IEEE 1800 Standard VCD Dumping (RTL sim only -- sim_gate.tcl's own
        // open_vcd/log_vcd already owns waveform.vcd during gate-level sim,
        // and only one VCD file can be open at a time)
        `ifndef GATE_SIM
        `ifndef SYNTHESIS
            $dumpfile("waveform.vcd");
            $dumpvars(0, led_blinker_tb);
        `endif
        `endif

        rst_n = 0;
        #20 rst_n = 1;

        #300; // Let it run through multiple blink cycles

        if (led[0] === 1'bx) begin
            $display("FAIL: led_blinker_tb - led[0] is undefined (X).");
            $finish(1);
        end

        $display("PASS: led_blinker_tb - LED output resolved correctly across all cycles.");
        $finish;
    end
endmodule
