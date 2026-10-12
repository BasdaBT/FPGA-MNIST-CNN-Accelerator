`timescale 1ns / 1ps

module dense_layer_2 #(
    parameter SHIFT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Dense 1 RAM'inden Okuma (Giriş)
    output reg [4:0] o_ram_addr, // 0-31 arası
    input wire signed [7:0] i_ram_data,
    
    // Sonuç Çıkışı (32 Nöron)
    output reg output_valid,
    output reg [4:0] output_neuron_idx, // 0-31
    output reg signed [7:0] output_data,
    output reg done
);

    localparam IDLE = 0;
    localparam SETUP_ADDR = 1;
    localparam WAIT_RAM = 2;
    localparam MAC = 3;
    localparam BIAS_RELU = 4;
    localparam WRITE = 5;

    reg [2:0] state;
    
    reg [4:0] input_idx;  // Sadece 32 giriş var (0-31)
    reg [4:0] neuron_idx; // 32 çıkış nöronu (0-31)
    
    reg signed [31:0] acc; 
    
    // Ağırlık ROM: 32*32 = 1024 adres (10 bit yeter)
    reg [9:0] weight_addr; 
    wire signed [7:0] weight_data;
    
    // Bias ROM
    wire signed [7:0] bias_data;
    
    // ROM Modülleri (Kodlarını aşağıda vereceğim)
    rom_weights_dense2 w_rom (.clk(clk), .addr(weight_addr), .data(weight_data));
    rom_bias_dense2    b_rom (.clk(clk), .addr(neuron_idx),  .data(bias_data)); 

    reg signed [31:0] temp_val;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            neuron_idx <= 0; input_idx <= 0; acc <= 0;
            done <= 0; output_valid <= 0;
            o_ram_addr <= 0; weight_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0; output_valid <= 0;
                    if (start) begin
                        state <= SETUP_ADDR;
                        neuron_idx <= 0; input_idx <= 0; acc <= 0;
                    end
                end

                // 1. Veri ve Ağırlık İste
                SETUP_ADDR: begin
                    o_ram_addr <= input_idx; // 0..31
                                        // Ağırlık Adresi (Python/Numpy C-order): (GirişID * 32) + NöronID
                    weight_addr <= (input_idx * 32) + neuron_idx; 
                    state <= WAIT_RAM;
                end

                // 2. Bekle
                WAIT_RAM: state <= MAC;

                // 3. Hesapla
                MAC: begin
                    acc <= acc + (i_ram_data * weight_data);
                    
                    if (input_idx == 31) begin // Sadece 32 giriş var
                        state <= BIAS_RELU;
                    end else begin
                        input_idx <= input_idx + 1;
                        state <= SETUP_ADDR;
                    end
                end

                // 4. Bias -> ReLU -> Shift -> Clamp
                BIAS_RELU: begin
                    temp_val = acc + bias_data;
                    
                    // ReLU
                    if (temp_val < 0) temp_val = 0;
                    
                    // Shift
                    temp_val = temp_val >>> SHIFT;
                    
                    // Clamp
                    if (temp_val > 127) temp_val = 127;
                    else if (temp_val < -128) temp_val = -128;
                    
                    output_data <= temp_val[7:0];
                    output_neuron_idx <= neuron_idx;
                    output_valid <= 1;
                    
                    state <= WRITE;
                end
                
                // 5. Yaz ve İlerle
                WRITE: begin
                    output_valid <= 0;
                    acc <= 0;
                    input_idx <= 0;
                    
                    if (neuron_idx == 31) begin
                        state <= IDLE;
                        done <= 1;
                    end else begin
                        neuron_idx <= neuron_idx + 1;
                        state <= SETUP_ADDR;
                    end
                end
            endcase
        end
    end
endmodule