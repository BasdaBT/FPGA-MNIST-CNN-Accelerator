`timescale 1ns/1ps

module tb_cnn_top;

  reg  clk;
  reg  rst_n;
  reg  start;

  wire [9:0] o_image_addr;
  wire [7:0] i_image_data;

  wire        valid_result;
  wire [3:0]  predicted_digit;
  wire        done;

  // Clock: 100 MHz (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // Fail fast if the inference pipeline stalls.
  initial begin
    #5_000_000;
    $fatal(1, "TIMEOUT: inference did not finish within 5 ms");
  end

  // Image ROM (cnn_top -> image_addr, rom -> image_data)
  image_rom u_img (
    .clk (clk),
    .addr(o_image_addr),
    .data(i_image_data)
  );

  // DUT
  cnn_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),

    .o_image_addr(o_image_addr),
    .i_image_data(i_image_data),

    .valid_result(valid_result),
    .predicted_digit(predicted_digit),
    .done(done)
  );

  task run_inference;
    input integer run_id;
    begin
      start = 1;
      #10;
      start = 0;

      wait (done == 1'b1);
      $display("RUN %0d DONE: predicted_digit=%0d valid=%0b t=%0t", run_id, predicted_digit, valid_result, $time);
      wait (done == 1'b0);
      #20;
    end
  endtask

  initial begin
    // init
    rst_n = 0;
    start = 0;

    // reset
    #50;
    rst_n = 1;

    // Run twice to verify that the pipeline can restart without reset.
    #50;
    run_inference(1);
    run_inference(2);
    #50;
    $finish;
  end

endmodule
