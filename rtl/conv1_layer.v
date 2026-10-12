`timescale 1ns / 1ps

module conv1_layer (
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Image ROM
    output reg [9:0] o_image_addr,
    input wire [7:0] i_image_data,
    
    // Çıkış (ARTIK 32-BIT!)
    output reg output_valid,
    output reg [1:0] output_filter,
    output reg signed [31:0] output_data, // Değişti: [7:0] -> [31:0]
    output reg done
);

    localparam IDLE = 0, LOAD_PIXEL = 1, WAIT_RAM = 2, CALC = 3, WAIT_BIAS = 4, BIAS_RELU = 5, SEND_OUT = 6;
    reg [2:0] state;

    reg [4:0] row, col;      
    reg [3:0] win_r, win_c;  
    reg [2:0] filter_idx;    
    reg signed [31:0] acc;   
    
    reg [5:0] weight_addr;
    wire signed [7:0] weight_data;
    
    reg [1:0] bias_addr;
    wire signed [15:0] bias_data;

    rom_weights_conv1 w_rom (.clk(clk), .addr(weight_addr), .data(weight_data));
    rom_bias_conv1    b_rom (.clk(clk), .addr(bias_addr),   .data(bias_data));

    reg signed [31:0] temp_val;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            row <= 0; col <= 0; win_r <= 0; win_c <= 0; filter_idx <= 0;
            acc <= 0; done <= 0; output_valid <= 0; o_image_addr <= 0; weight_addr <= 0; bias_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0; output_valid <= 0;
                    if (start) begin
                        state <= LOAD_PIXEL;
                        row <= 0; col <= 0; filter_idx <= 0; win_r <= 0; win_c <= 0; acc <= 0;
                    end
                end

                LOAD_PIXEL: begin
                    o_image_addr <= (row + win_r) * 28 + (col + win_c);
                    weight_addr <= ((win_r * 3) + win_c) * 4 + filter_idx;
                    state <= WAIT_RAM;
                end

                WAIT_RAM: state <= CALC;

                CALC: begin
                    acc <= acc + ($signed({1'b0, i_image_data}) * weight_data);
                    if (win_c == 2) begin
                        win_c <= 0;
                        if (win_r == 2) begin
                            win_r <= 0;
                            bias_addr <= filter_idx[1:0]; 
                            state <= WAIT_BIAS; 
                        end else begin
                            win_r <= win_r + 1; state <= LOAD_PIXEL; 
                        end
                    end else begin
                        win_c <= win_c + 1; state <= LOAD_PIXEL; 
                    end
                end
                
                WAIT_BIAS: state <= BIAS_RELU;

                BIAS_RELU: begin
                    // 1. Bias Ekle
                    temp_val = acc + bias_data;
                    
                    // 2. ReLU (Sadece negatifleri sıfırla, SHIFT YOK!)
                    if (temp_val < 0) temp_val = 0; 
                    
                    // Çıkışa 32-bit olarak veriyoruz
                    output_data <= temp_val;
                    output_filter <= filter_idx[1:0];
                    output_valid <= 1;
                    
                    state <= SEND_OUT;
                end
                
                SEND_OUT: begin
                    output_valid <= 0;
                    acc <= 0; 
                    if (filter_idx == 3) begin
                        filter_idx <= 0;
                        if (col == 25) begin
                            col <= 0;
                            if (row == 25) begin
                                state <= IDLE; done <= 1;
                            end else begin
                                row <= row + 1; state <= LOAD_PIXEL;
                            end
                        end else begin
                            col <= col + 1; state <= LOAD_PIXEL;
                        end
                    end else begin
                        filter_idx <= filter_idx + 1; state <= LOAD_PIXEL; 
                    end
                end
            endcase
        end
    end
endmodule