`timescale 1ns / 1ps
module rom_weights_output(input wire clk, input wire [8:0] addr, output reg signed [7:0] data);
    (* ram_style = "block" *)
    reg signed [7:0] mem [0:319]; // 10 rakam * 32 giriş = 320
    initial $readmemh("output_weights_hex.txt", mem); // Yolu ayarla!
    always @(posedge clk) data <= mem[addr];
endmodule