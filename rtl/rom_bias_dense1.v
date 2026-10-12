`timescale 1ns / 1ps
module rom_bias_dense1(
    input wire clk,
    input wire [4:0] addr, 
    output reg signed [7:0] data
);
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:31]; 

    initial begin
        $readmemh("dense1_bias_hex.txt", mem);
    end

    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule