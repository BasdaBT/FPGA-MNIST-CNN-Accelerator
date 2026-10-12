`timescale 1ns / 1ps

module image_rom (
    input wire clk,
    input wire [9:0] addr,  // 0-783 arası adres
    output reg [7:0] data   // 8-bit piksel verisi
);

    // 784 elemanlı hafıza
    (* ram_style = "block" *)
    reg [7:0] rom_memory [0:783];

    initial begin
        // Yüklediğiniz dosyanın tam adı buraya yazıldı
        $readmemh("test_image_8_label_5_hex.txt", rom_memory);
    end

    always @(posedge clk) begin
        data <= rom_memory[addr];
    end

endmodule