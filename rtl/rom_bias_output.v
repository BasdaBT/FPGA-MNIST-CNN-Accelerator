`timescale 1ns / 1ps
module rom_bias_output(input wire clk, input wire [3:0] addr, output reg signed [7:0] data);
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:9]; // 10 rakam
    initial $readmemh("output_bias_hex.txt", mem); // Yolu ayarla!
    always @(posedge clk) data <= mem[addr];
endmodule