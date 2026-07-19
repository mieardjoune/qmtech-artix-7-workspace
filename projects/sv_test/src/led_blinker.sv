// =============================================================================
// File        : led_blinker.sv
// Project      : qmtech-workspace / sv_test
// Standard     : IEEE 1800-2012 (SystemVerilog)
// Description  : Free-running clock divider that toggles a complementary
//                2-bit LED output at a rate set by the BLINK_MAX parameter.
// =============================================================================
`timescale 1ns / 1ps

module led_blinker #(
    parameter int BLINK_MAX = 25_000_000  // 50 MHz clk / 2 -> 1 Hz blink (0.5s on, 0.5s off)
)(
    input  logic clk,
    input  logic rst_n,
    output logic [1:0] led
);
    int counter;
    logic state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            state   <= 0;
        end else begin
            if (counter >= BLINK_MAX - 1) begin
                counter <= 0;
                state   <= ~state;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    assign led[0] = state;
    assign led[1] = ~state;

endmodule
