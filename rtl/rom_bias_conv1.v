`timescale 1ns / 1ps

module rom_bias_conv1 (
    input wire clk,
    input wire [1:0] addr, // 4 filtre için 2 bit adres (0-3)
    output reg signed [15:0] data // 16-bit signed bias (PDF referansı)
);
    // HATA ÇÖZÜMÜ: Hafızayı 32-bit tanımlıyoruz.
    // Böylece dosya içinde "FFFFFFF8" gibi uzun hexler varsa bile sığar.
    (* ram_style = "block" *)
    reg [31:0] mem [0:3];

    initial begin
        $readmemh("conv1_bias_hex.txt", mem);
    end

    always @(posedge clk) begin
        // Dosyadan okunan değerin sadece son 8 bitini alıyoruz (Truncation)
                data <= mem[addr][15:0];
    end
endmodule