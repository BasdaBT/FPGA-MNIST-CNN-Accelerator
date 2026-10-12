`timescale 1ns / 1ps

module rom_weights_conv1 (
    input wire clk,
    input wire [5:0] addr, // 36 adet ağırlık
    output reg signed [7:0] data
);
    // 1. HATA ÇÖZÜMÜ:
    // Dosyadaki 'E5' gibi verileri garantili okumak için
    // hafızayı geçici olarak 32-bit tanımlıyoruz.
    (* ram_style = "block" *)
    reg [31:0] mem [0:35];

    initial begin
        // Hex dosyasını yükle
        $readmemh("conv1_weights_hex.txt", mem);
    end

    always @(posedge clk) begin
        // 2. HATA ÇÖZÜMÜ:
        // 32-bitlik verinin sadece en sağdaki 8 bitini (LSB) alıyoruz.
        // Böylece sayı ne formatta olursa olsun doğru (E5) alınır.
        data <= mem[addr][7:0];
    end
endmodule