`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import packet_uvc_pkg::*;

  localparam int DATA_WIDTH = 8;
  localparam int FIFO_DEPTH = 64;

  logic clk = 1'b0;

  packet_if #(DATA_WIDTH) write_if(clk);
  packet_if #(DATA_WIDTH) read_if(clk);

  packet_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(FIFO_DEPTH)
  ) dut (
    .clk       (clk),
    .rst       (write_if.rst),
    .in_sop    (write_if.sop),
    .in_eop    (write_if.eop),
    .in_valid  (write_if.valid),
    .in_data   (write_if.data),
    .in_wr_en  (write_if.wr_en),
    .out_sop   (read_if.sop),
    .out_eop   (read_if.eop),
    .out_valid (read_if.valid),
    .out_data  (read_if.data),
    .out_rd_en (read_if.rd_en)
  );

  always #5 clk = ~clk;

  // The active read agent drives rd_en. Unused opposite-direction enables
  // remain tied low.
  assign read_if.rst    = write_if.rst;
  assign read_if.wr_en  = 1'b0;
  assign write_if.rd_en = 1'b0;

  initial begin
    write_if.rst = 1'b1;
    repeat (5) @(posedge clk);
    write_if.rst <= 1'b0;
  end

  initial begin
    uvm_config_db#(virtual packet_if)::set(
      null, "uvm_test_top", "write_vif", write_if
    );
    uvm_config_db#(virtual packet_if)::set(
      null, "uvm_test_top", "read_vif", read_if
    );
    run_test("packet_wr_en_variation_test");
  end

  initial begin
    #10000;
    `uvm_fatal("TIMEOUT", "Simulation exceeded 10 us")
  end
endmodule
