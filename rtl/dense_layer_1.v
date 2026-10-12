`timescale 1ns / 1ps

module dense_layer_1 #(
    parameter SHIFT = 9
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Flatten RAM'den Okuma
    output reg [9:0] o_flat_addr, // 0-675
    input wire signed [7:0] i_flat_data,
    
    // Sonuç Çıkışı (32 Nöron)
    output reg output_valid,
    output reg [4:0] output_neuron_idx, // 0-31
    output reg signed [7:0] output_data,
    output reg done
);

    localparam IDLE = 0;
    localparam SETUP_ADDR = 1; // Adres ver
    localparam WAIT_RAM = 2;   // RAM'i bekle
    localparam MAC = 3;        // Çarp ve Topla
    localparam BIAS_RELU = 4;  // İşlem bitince Bias, ReLU, Shift
    localparam WRITE = 5;      // Yaz

    reg [2:0] state;
    
    reg [9:0] input_idx; // 676 giriş sayacı
    reg [4:0] neuron_idx; // 32 nöron sayacı
    
    reg signed [31:0] acc; // Toplam (Accumulator)
    
    // Ağırlık ROM
    reg [14:0] weight_addr; // 32 * 676 = 21632 adres (15-bit yeter)
    wire signed [7:0] weight_data;
    
    // Bias ROM
    wire signed [7:0] bias_data; // Adres direkt neuron_idx'tir
    
    // ROM Modülleri
    rom_weights_dense1 w_rom (.clk(clk), .addr(weight_addr), .data(weight_data));
    rom_bias_dense1    b_rom (.clk(clk), .addr(neuron_idx),  .data(bias_data)); // Adres direkt nöron ID

    reg signed [31:0] temp_val;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            neuron_idx <= 0; input_idx <= 0; acc <= 0;
            done <= 0; output_valid <= 0;
            o_flat_addr <= 0; weight_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0; output_valid <= 0;
                    if (start) begin
                        state <= SETUP_ADDR;
                        neuron_idx <= 0; 
                        input_idx <= 0; 
                        acc <= 0;
                    end
                end

                // 1. Veri İste
                SETUP_ADDR: begin
                    o_flat_addr <= input_idx;
                    // Ağırlık Adresi: (NöronID * 676) + GirişID
                                        // Ağırlık Adresi (Python/Numpy C-order): (GirişID * 32) + NöronID
                    weight_addr <= (input_idx * 32) + neuron_idx; 
                    state <= WAIT_RAM;
                end

                // 2. Bekle (RAM Latency)
                WAIT_RAM: state <= MAC;

                // 3. Hesapla (MAC)
                MAC: begin
                    acc <= acc + (i_flat_data * weight_data);
                    
                    if (input_idx == 675) begin
                        // Bu nöron için tüm girişler bitti
                        state <= BIAS_RELU;
                    end else begin
                        input_idx <= input_idx + 1;
                        state <= SETUP_ADDR;
                    end
                end

                // 4. Son İşlemler (Bias -> ReLU -> Shift -> Clamp)
                BIAS_RELU: begin
                    // Bias ekle
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
                
                // 5. Yaz ve Sonraki Nörona Geç
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