`timescale 1ns / 1ps
// Basys 3 top-level demo wrapper for cnn_top + image_rom.
// - BTN_C : reset
// - BTN_U : start (debounced; rising edge -> 1-cycle pulse in CNN clock domain)
// - 7-seg: shows predicted digit on AN0 when valid
// - LED0 : done (latched)
module basys3_cnn_demo #(
    // CNN clock divider:
    // If DIV_TOGGLE <= 1 -> clk_cnn = CLK100MHZ (100MHz)
    // Else clk_cnn toggles every DIV_TOGGLE cycles of CLK100MHZ.
    // Effective f_cnn = 100MHz / (2*DIV_TOGGLE).
    // Example: DIV_TOGGLE=5 -> 10MHz.
    parameter integer DIV_TOGGLE = 5
)(
    input  wire        CLK100MHZ,
    input  wire        btnC,
    input  wire        btnU,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,
    output wire [15:0] led
);

    // ---------------------------------------------------------------------
    // Clock divider for CNN core (optional; per project hint).
    // ---------------------------------------------------------------------
    wire clk_cnn;

    generate
        if (DIV_TOGGLE <= 1) begin : gen_no_div
            assign clk_cnn = CLK100MHZ;
        end else begin : gen_div
            localparam integer DIVW = (DIV_TOGGLE <= 2) ? 1 : $clog2(DIV_TOGGLE);
            reg [DIVW-1:0] div_cnt = {DIVW{1'b0}};
            reg clk_cnn_r = 1'b0;

            always @(posedge CLK100MHZ) begin
                if (div_cnt == DIV_TOGGLE-1) begin
                    div_cnt   <= {DIVW{1'b0}};
                    clk_cnn_r <= ~clk_cnn_r;
                end else begin
                    div_cnt <= div_cnt + 1'b1;
                end
            end

            assign clk_cnn = clk_cnn_r;
        end
    endgenerate

    // ---------------------------------------------------------------------
    // Reset for CNN core: active-low async asserted, sync deasserted to clk_cnn
    // ---------------------------------------------------------------------
    wire rst_n_async = ~btnC;

    reg [2:0] rst_pipe;
    always @(posedge clk_cnn or negedge rst_n_async) begin
        if (!rst_n_async) rst_pipe <= 3'b000;
        else             rst_pipe <= {rst_pipe[1:0], 1'b1};
    end
    wire rst_n = rst_pipe[2];

    // ---------------------------------------------------------------------
    // Debounce start button in CLK100MHZ domain, then edge-detect in clk_cnn
    // ---------------------------------------------------------------------
    wire btnU_db;

    debounce #(.CTR_WIDTH(18)) u_db_start (
        .clk  (CLK100MHZ),
        .rst_n(rst_n_async),
        .din  (btnU),
        .db   (btnU_db)
    );

    reg start_db_d;
    always @(posedge clk_cnn or negedge rst_n) begin
        if (!rst_n) start_db_d <= 1'b0;
        else       start_db_d <= btnU_db;
    end
    wire start_pulse = btnU_db & ~start_db_d;

    // ---------------------------------------------------------------------
    // CNN core + image ROM
    // ---------------------------------------------------------------------
    wire [9:0] image_addr;
    wire [7:0] image_data;

    wire valid_result;
    wire [3:0] predicted_digit;
    wire done;

    cnn_top u_cnn (
        .clk(clk_cnn),
        .rst_n(rst_n),
        .start(start_pulse),
        .o_image_addr(image_addr),
        .i_image_data(image_data),
        .valid_result(valid_result),
        .predicted_digit(predicted_digit),
        .done(done)
    );

    image_rom u_img (
        .clk (clk_cnn),
        .addr(image_addr),
        .data(image_data)
    );

    // ---------------------------------------------------------------------
    // Latch result for display
    // ---------------------------------------------------------------------
    reg [3:0] digit_latched;
    reg       show;
    reg       done_latched;

    always @(posedge clk_cnn or negedge rst_n) begin
        if (!rst_n) begin
            digit_latched <= 4'd0;
            show          <= 1'b0;
            done_latched  <= 1'b0;
        end else begin
            if (start_pulse) begin
                show         <= 1'b0;
                done_latched <= 1'b0;
            end

            if (valid_result) begin
                digit_latched <= predicted_digit;
                show          <= 1'b1;
            end

            if (done) done_latched <= 1'b1;
        end
    end

    sevenseg_basys3_hex0 u_7seg (
        .val(digit_latched),
        .enable(show),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    assign led = {15'b0, done_latched};

endmodule
