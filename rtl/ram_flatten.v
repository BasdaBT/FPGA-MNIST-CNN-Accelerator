`timescale 1ns / 1ps

module ram_flatten (
    input wire clk,
    
    // Yazma Portu (MaxPool'dan gelen veriler buraya)
    input wire we,
    input wire [9:0] w_addr, // 676 için 10 bit adres yeterli (2^10 = 1024)
    input wire [7:0] w_data,
    
    // Okuma Portu (Dense Layer buradan okuyacak)
    input wire [9:0] r_addr,
    output reg [7:0] r_data
);

    (* ram_style = "block" *)
    reg [7:0] mem [0:675]; // 0'dan 675'e kadar 676 hücre

    // Yazma
    always @(posedge clk) begin
        if (we) begin
            mem[w_addr] <= w_data;
        end
    end

    // Okuma
    always @(posedge clk) begin
        r_data <= mem[r_addr];
    end

endmodule