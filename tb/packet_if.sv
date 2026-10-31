interface packet_if #(
  parameter int DATA_WIDTH = 8
) (
  input logic clk
);
  logic                  rst;
  logic                  sop;
  logic                  eop;
  logic                  valid;
  logic [DATA_WIDTH-1:0] data;
  logic                  rd_en;
  logic                  wr_en;

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst;
    input sop;
    input eop;
    input valid;
    input data;
    input rd_en;
    input wr_en;
  endclocking

endinterface
