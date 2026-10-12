`timescale 1ns/1ps

module cnn_top_with_rom(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output wire valid_result,
    output wire [3:0] predicted_digit,
    output wire done
);
    wire [9:0] addr;
    wire [7:0] pix;

    cnn_top u_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .o_image_addr(addr),
        .i_image_data(pix),
        .valid_result(valid_result),
        .predicted_digit(predicted_digit),
        .done(done)
    );

    image_rom u_rom (
        .clk(clk),
        .addr(addr),
        .data(pix)
    );

endmodule
