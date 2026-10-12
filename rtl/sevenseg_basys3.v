`timescale 1ns / 1ps
// Basys 3 7-seg encoder (active-low) for a single digit.
// seg[6:0] = {g,f,e,d,c,b,a}
module sevenseg_digit(
    input  wire [3:0] val,
    input  wire       enable,
    output reg  [6:0] seg
);
    always @(*) begin
        if (!enable) begin
            seg = 7'b1111111; // blank
        end else begin
            case (val)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b0111111; // dash
            endcase
        end
    end
endmodule

// Basys 3 wrapper: drives only AN0. dp is off.
module sevenseg_basys3_hex0(
    input  wire [3:0] val,
    input  wire       enable,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       dp
);
    assign an = 4'b1110; // enable AN0 only (active-low)
    assign dp = 1'b1;    // off (active-low)

    sevenseg_digit u_enc(
        .val(val),
        .enable(enable),
        .seg(seg)
    );
endmodule
