`timescale 1ns / 1ps
module rom_weights_dense2(input wire clk, input wire [9:0] addr, output reg signed [7:0] data);
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:1023]; // 32*32
    initial $readmemh("dense2_weights_hex.txt", mem); // Yolu düzelt!
    always @(posedge clk) data <= mem[addr];
endmodule