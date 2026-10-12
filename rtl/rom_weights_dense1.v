`timescale 1ns / 1ps
module rom_weights_dense1(
    input wire clk,
    input wire [14:0] addr, // 21632 veri için 15 bit lazım
    output reg signed [7:0] data
);
    // Dosya yolunu kendine göre ayarla!
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:21631]; 

    initial begin
        $readmemh("dense1_weights_hex.txt", mem);
    end

    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule