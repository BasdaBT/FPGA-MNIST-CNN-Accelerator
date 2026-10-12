`timescale 1ns / 1ps
module rom_bias_dense2(input wire clk, input wire [4:0] addr, output reg signed [7:0] data);
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:31];
    initial $readmemh("dense2_bias_hex.txt", mem); // Yolu düzelt!
    always @(posedge clk) data <= mem[addr];
endmodule