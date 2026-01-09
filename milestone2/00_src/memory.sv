module memory #(
  parameter int unsigned BYTES = 2048,
  parameter integer FILENAME_LEN = 256,
  parameter [8*FILENAME_LEN-1:0] MEM_FILE = "mem.dump"
)(
  input  logic        i_clk, i_we, i_re,
  input  logic [31:0] i_addr, i_wdata,
  output logic [31:0] o_rdata
);
  localparam int WORDS = BYTES/4;
  logic [31:0] mem[0:WORDS-1];
  reg   [8*FILENAME_LEN-1:0] path;

  initial begin
    if (!$value$plusargs("DMEM=%s", path)) path = MEM_FILE;
    $display("[DMEM] loading: %s", path);
    $readmemh(path, mem);
  end

  assign o_rdata = i_re ? mem[i_addr[31:2]] : 32'd0;

  always_ff @(posedge i_clk) begin
    if (i_we) mem[i_addr[31:2]] <= i_wdata;
  end
endmodule
