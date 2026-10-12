`timescale 1ns / 1ps

module ram_conv_output (
    input wire clk,
    input wire we,
    input wire [11:0] w_addr,
    input wire [31:0] w_data, // Değişti: [7:0] -> [31:0]
    
    input wire [11:0] r_addr,
    output reg [31:0] r_data  // Değişti: [7:0] -> [31:0]
);

    // 2704 adet 32-bitlik hafıza
    (* ram_style = "block" *)
    reg [31:0] mem [0:2703];

    always @(posedge clk) begin
        if (we) begin
            mem[w_addr] <= w_data;
        end
    end

    always @(posedge clk) begin
        r_data <= mem[r_addr];
    end
endmodule