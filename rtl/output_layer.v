`timescale 1ns / 1ps

module output_layer (
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Dense 2 RAM'inden Okuma
    output reg [4:0] o_ram_addr, // 0-31
    input wire signed [7:0] i_ram_data,
    
    // FİNAL ÇIKIŞ (Tahmin Edilen Rakam)
    output reg valid,
    output reg [3:0] prediction, // 0-9 arası rakam
    output reg done
);

    localparam IDLE = 0;
    localparam SETUP_ADDR = 1;
    localparam WAIT_RAM = 2;
    localparam MAC = 3;
    localparam ADD_BIAS = 4;
    localparam COMPARE = 5;

    reg [2:0] state;
    
    reg [4:0] input_idx;  // 32 giriş (0-31)
    reg [3:0] digit_idx;  // 10 rakam (0-9)
    
    reg signed [31:0] acc; 
    
    // Ağırlık ROM: 10 rakam * 32 giriş = 320 ağırlık
    reg [8:0] weight_addr; 
    wire signed [7:0] weight_data;
    
    // Bias ROM: 10 bias
    wire signed [7:0] bias_data;
    
    // Argmax için değişkenler
    reg signed [31:0] max_score; // O ana kadarki en yüksek skor
    reg [3:0] best_digit;        // O skora sahip rakam
    
    // ROM Modülleri (Kodlarını aşağıda vereceğim)
    rom_weights_output w_rom (.clk(clk), .addr(weight_addr), .data(weight_data));
    rom_bias_output    b_rom (.clk(clk), .addr(digit_idx),   .data(bias_data)); 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            digit_idx <= 0; input_idx <= 0; acc <= 0;
            done <= 0; valid <= 0; prediction <= 0;
            max_score <= -2147483648; // En küçük mümkün sayı (Negatif sonsuz gibi)
            best_digit <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0; valid <= 0;
                    if (start) begin
                        state <= SETUP_ADDR;
                        digit_idx <= 0; input_idx <= 0; acc <= 0;
                        max_score <= -2147483648; // Resetle
                    end
                end

                // 1. Veri ve Ağırlık İste
                SETUP_ADDR: begin
                    o_ram_addr <= input_idx;
                    // Adres: (Rakam * 32) + Giriş
                                        // Adres (Python/Numpy C-order, w_out şekli (32,10)): (GirişID * 10) + RakamID
                    weight_addr <= (input_idx * 10) + digit_idx; 
                    state <= WAIT_RAM;
                end

                // 2. Bekle
                WAIT_RAM: state <= MAC;

                // 3. Hesapla (MAC)
                MAC: begin
                    acc <= acc + (i_ram_data * weight_data);
                    
                    if (input_idx == 31) begin // 32 giriş bitti
                        state <= ADD_BIAS;
                    end else begin
                        input_idx <= input_idx + 1;
                        state <= SETUP_ADDR;
                    end
                end

                // 4. Bias Ekle (RELU YOK!)
                ADD_BIAS: begin
                    acc <= acc + bias_data; // Ham skor (Raw Score)
                    state <= COMPARE;
                end
                
                // 5. Karşılaştır (Argmax)
                COMPARE: begin
                    // Eğer şu anki skor, rekor skorudan büyükse; yeni kral bu!
                    if (acc > max_score) begin
                        max_score <= acc;
                        best_digit <= digit_idx;
                    end
                    
                    // Sonraki rakama geç
                    acc <= 0;
                    input_idx <= 0;
                    
                    if (digit_idx == 9) begin
                        // Tüm rakamlar bitti! Sonucu açıkla.
                        // Handle the final comparison directly because the
                        // nonblocking best_digit update lands next cycle.
                        if (acc > max_score) prediction <= digit_idx;
                        else prediction <= best_digit;

                        valid <= 1;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        digit_idx <= digit_idx + 1;
                        state <= SETUP_ADDR;
                    end
                end
            endcase
        end
    end
endmodule
