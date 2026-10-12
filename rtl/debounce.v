`timescale 1ns / 1ps
// Simple, parameterizable debouncer for mechanical pushbuttons.
// Produces a stable debounced level in 'db'.
// Note: This is not an edge detector; do edge detect separately.
module debounce #(
    parameter integer CTR_WIDTH = 18  // ~2.6ms @100MHz (2^18 / 100e6)
)(
    input  wire clk,
    input  wire rst_n,     // active-low async reset
    input  wire din,       // async/noisy input
    output reg  db         // debounced output
);
    // 2FF synchronizer
    reg din_ff1, din_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_ff1 <= 1'b0;
            din_ff2 <= 1'b0;
        end else begin
            din_ff1 <= din;
            din_ff2 <= din_ff1;
        end
    end

    reg [CTR_WIDTH-1:0] cnt;
    reg din_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= {CTR_WIDTH{1'b0}};
            din_stable<= 1'b0;
            db        <= 1'b0;
        end else begin
            // if input changed, restart counter
            if (din_ff2 != din_stable) begin
                din_stable <= din_ff2;
                cnt        <= {CTR_WIDTH{1'b0}};
            end else begin
                // if stable long enough, update debounced output
                if (&cnt) begin
                    db <= din_stable;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end
endmodule
