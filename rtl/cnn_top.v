`timescale 1ns / 1ps

module cnn_top(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Resim Girişi
    output wire [9:0] o_image_addr,
    input wire [7:0] i_image_data,
    
    // FİNAL SONUÇ
    output wire valid_result,
    output wire [3:0] predicted_digit,
    output wire done
);

    // ==========================================
    // SİNYALLER
    // ==========================================

    // --- 1. Conv1 & Ara RAM (32-Bit) ---
    wire c1_valid, c1_done; 
    wire [1:0] c1_filter; 
    wire signed [31:0] c1_data;      
    wire ram1_we; 
    wire [11:0] ram1_w_addr; 
    wire signed [31:0] ram1_r_data;
    reg [4:0] w_row, w_col; 

    // --- 2. MaxPool & Flatten (8-Bit) ---
    reg mp_start; 
    wire mp_valid, mp_done; 
    wire signed [7:0] mp_data_out; 
    wire [11:0] mp_read_addr;

    wire [9:0] flatten_w_addr;
    wire [9:0] flatten_r_addr; 
    wire signed [7:0] flatten_r_data;

    // --- 3. Dense & Output ---
    reg d1_start; wire d1_done; wire d1_valid; wire [4:0] d1_neuron_idx; wire signed [7:0] d1_data;
    wire [4:0] ram_d1_r_addr; wire signed [7:0] ram_d1_r_data;
    
    reg d2_start; wire d2_done; wire d2_valid; wire [4:0] d2_neuron_idx; wire signed [7:0] d2_data;
    wire [4:0] ram_d2_r_addr; wire signed [7:0] ram_d2_r_data;
    
    reg out_start; wire out_done;

    // ==========================================
    // MODÜL BAĞLANTILARI
    // ==========================================

    conv1_layer u_conv1 ( .clk(clk), .rst_n(rst_n), .start(start), .o_image_addr(o_image_addr), .i_image_data(i_image_data), .output_valid(c1_valid), .output_filter(c1_filter), .output_data(c1_data), .done(c1_done));
    
    ram_conv_output u_ram1 ( .clk(clk), .we(ram1_we), .w_addr(ram1_w_addr), .w_data(c1_data), .r_addr(mp_read_addr), .r_data(ram1_r_data));
    
    maxpool_layer u_maxpool (
        .clk(clk), .rst_n(rst_n), .start(mp_start), 
        .o_addr(mp_read_addr), .i_data(ram1_r_data),
        .valid(mp_valid), 
        .data_out(mp_data_out), 
        .done(mp_done)
    );

    ram_flatten u_ram_flatten ( .clk(clk), .we(mp_valid), .w_addr(flatten_w_addr), .w_data(mp_data_out), .r_addr(flatten_r_addr), .r_data(flatten_r_data));
    
    // DİKKAT: Dense 1 Shift Değeri 9 Olarak Ayarlandı!
    dense_layer_1 #(
        .SHIFT(9) 
    ) u_dense1 ( 
        .clk(clk), .rst_n(rst_n), .start(d1_start), 
        .o_flat_addr(flatten_r_addr), .i_flat_data(flatten_r_data), 
        .output_valid(d1_valid), .output_neuron_idx(d1_neuron_idx), .output_data(d1_data), .done(d1_done)
    );
    
    ram_dense1 u_ram_d1 ( .clk(clk), .we(d1_valid), .w_addr(d1_neuron_idx), .w_data(d1_data), .r_addr(ram_d1_r_addr), .r_data(ram_d1_r_data));
    
    dense_layer_2 u_dense2 ( .clk(clk), .rst_n(rst_n), .start(d2_start), .o_ram_addr(ram_d1_r_addr), .i_ram_data(ram_d1_r_data), .output_valid(d2_valid), .output_neuron_idx(d2_neuron_idx), .output_data(d2_data), .done(d2_done));
    
    ram_dense2 u_ram_d2 ( .clk(clk), .we(d2_valid), .w_addr(d2_neuron_idx), .w_data(d2_data), .r_addr(ram_d2_r_addr), .r_data(ram_d2_r_data));
    
    output_layer u_output ( .clk(clk), .rst_n(rst_n), .start(out_start), .o_ram_addr(ram_d2_r_addr), .i_ram_data(ram_d2_r_data), .valid(valid_result), .prediction(predicted_digit), .done(out_done));

    // ==========================================
    // KONTROL VE ADRES MANTIĞI
    // ==========================================

    // 1. Conv1 Adresleme
    assign ram1_we = c1_valid;
    assign ram1_w_addr = (c1_filter * 676) + (w_row * 26) + w_col;

    // --- YENİ ADRES HESAPLAMA (Safe Mode - X Hatasını Önler) ---
    // Sayaçlar
    reg [4:0] mp_row_cnt;    
    reg [4:0] mp_col_cnt;    
    reg [1:0] mp_filter_cnt; 

    // Hesabı "wire" ile dışarıda yapıyoruz (Gecikme ve X hatasını engeller)
    // Formül: ((Satır * 13) + Sütun) * 4 + Filtre
    wire [11:0] calc_idx_pixel;
    assign calc_idx_pixel = (mp_row_cnt * 13) + mp_col_cnt;
    
    wire [11:0] calc_final_addr;
    // (PikselID * 4) + FiltreID -> (*4 işlemi << 2 demektir)
    assign calc_final_addr = (calc_idx_pixel << 2) + mp_filter_cnt;
    assign flatten_w_addr = calc_final_addr[9:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_row <= 0; w_col <= 0; 
            mp_start <= 0; 
            mp_row_cnt <= 0; mp_col_cnt <= 0; mp_filter_cnt <= 0;
            d1_start <= 0; d2_start <= 0; out_start <= 0;
        end else begin
            // Layer start signals are one-cycle pulses. Keeping them asserted
            // would immediately restart a layer after it returns to IDLE.
            mp_start  <= 1'b0;
            d1_start  <= 1'b0;
            d2_start  <= 1'b0;
            out_start <= 1'b0;

            if (start) begin
               w_row <= 0; w_col <= 0; 
               mp_row_cnt <= 0; mp_col_cnt <= 0; mp_filter_cnt <= 0;
            end
            
            // Conv1 Mantığı
            if (c1_valid) begin 
                if (c1_filter == 3) begin 
                    if (w_col == 25) begin w_col <= 0; w_row <= w_row + 1; end 
                    else w_col <= w_col + 1; 
                end 
            end
            if (c1_done) mp_start <= 1;

            // FLATTEN MAPPING
            if (mp_valid) begin
                // Güvenli hesaplanan adresi kullan (10 bit)

                // Sayaçları Güncelle
                if (mp_col_cnt == 12) begin
                    mp_col_cnt <= 0;
                    if (mp_row_cnt == 12) begin
                        mp_row_cnt <= 0;
                        mp_filter_cnt <= mp_filter_cnt + 1; 
                    end else begin
                        mp_row_cnt <= mp_row_cnt + 1;
                    end
                end else begin
                    mp_col_cnt <= mp_col_cnt + 1;
                end
            end

            if (mp_done) d1_start <= 1;
            if (d1_done) d2_start <= 1;
            if (d2_done) out_start <= 1;
        end
    end
    
    assign done = out_done;

endmodule
