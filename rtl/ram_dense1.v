`timescale 1ns / 1ps

module ram_dense1 (
    input wire clk,
    input wire we,
    input wire [4:0] w_addr, // 32 nöron için 5 bit
    input wire [7:0] w_data,
    
    input wire [4:0] r_addr,
    output reg [7:0] r_data
);

    (* ram_style = "block" *)
    reg [7:0] mem [0:31];

    always @(posedge clk) begin
        if (we) mem[w_addr] <= w_data;
    end

    always @(posedge clk) begin
        r_data <= mem[r_addr];
    end
endmodule