`timescale 1ns / 1ps

module maxpool_layer #(
    parameter SHIFT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    output reg [11:0] o_addr,
    input wire signed [31:0] i_data, 
    
    output reg valid,
    output reg signed [7:0] data_out,
    output reg [1:0] filter_out,
    output reg done
);

    localparam IDLE=0;
    localparam ADDR_0=1, WAIT_0=2, READ_0=3;
    localparam ADDR_1=4, WAIT_1=5, READ_1=6;
    localparam ADDR_2=7, WAIT_2=8, READ_2=9;
    localparam ADDR_3=10, WAIT_3=11, READ_3=12;
    localparam COMPARE=13, SEND=14;

    reg [3:0] state;
    reg [3:0] row, col; 
    reg [1:0] filter; 
    
    reg signed [31:0] val0, val1, val2, val3;
    reg signed [31:0] max_val;
    
    reg signed [31:0] shifted_val;

    wire [11:0] base_addr;
    assign base_addr = (filter * 676) + (row * 52) + (col * 2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            row <= 0; col <= 0; filter <= 0;
            valid <= 0; done <= 0; o_addr <= 0;
        end else begin
            valid <= 0; // Varsayılan 0
            
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= ADDR_0;
                        row <= 0; col <= 0; filter <= 0;
                    end
                end

                // --- 1. PIKSEL ---
                ADDR_0: begin o_addr <= base_addr; state <= WAIT_0; end
                WAIT_0: state <= READ_0;
                READ_0: begin val0 <= i_data; state <= ADDR_1; end

                // --- 2. PIKSEL ---
                ADDR_1: begin o_addr <= base_addr + 1; state <= WAIT_1; end
                WAIT_1: state <= READ_1;
                READ_1: begin val1 <= i_data; state <= ADDR_2; end

                // --- 3. PIKSEL ---
                ADDR_2: begin o_addr <= base_addr + 26; state <= WAIT_2; end
                WAIT_2: state <= READ_2;
                READ_2: begin val2 <= i_data; state <= ADDR_3; end

                // --- 4. PIKSEL ---
                ADDR_3: begin o_addr <= base_addr + 27; state <= WAIT_3; end
                WAIT_3: state <= READ_3;
                READ_3: begin val3 <= i_data; state <= COMPARE; end

                // --- HESAPLAMA ---
                COMPARE: begin
                    if (val0 >= val1 && val0 >= val2 && val0 >= val3) max_val = val0;
                    else if (val1 >= val0 && val1 >= val2 && val1 >= val3) max_val = val1;
                    else if (val2 >= val0 && val2 >= val1 && val2 >= val3) max_val = val2;
                    else max_val = val3;

                    state <= SEND;
                end

                // --- ÇIKIŞ ---
                SEND: begin
                    // Shift ve Clamp
                    shifted_val = max_val >>> SHIFT;
                    if (shifted_val > 127) shifted_val = 127;
                    else if (shifted_val < -128) shifted_val = -128;
                    
                    data_out <= shifted_val[7:0];
                    valid <= 1; // Pulse
                    filter_out <= filter;
                    state <= ADDR_0; 

                    if (col == 12) begin
                        col <= 0;
                        if (row == 12) begin
                            row <= 0;
                            if (filter == 3) begin
                                // Finish with a one-cycle pulse so a new
                                // inference can start without a global reset.
                                state <= IDLE;
                                done <= 1;
                            end else begin
                                filter <= filter + 1;
                            end
                        end else begin
                            row <= row + 1;
                        end
                    end else begin
                        col <= col + 1;
                    end
                end
            endcase
        end
    end
endmodule
