module inst_mem #(
  parameter int unsigned BYTES = 8192,
  parameter integer FILENAME_LEN = 256,
  parameter [8*FILENAME_LEN-1:0] MEM_FILE = "isa_4b.hex"
)(
  input  logic [31:0] i_addr,
  output logic [31:0] o_rdata
);
  localparam int WORDS = BYTES/4;
  logic [31:0] rom[0:WORDS-1];
  reg   [8*FILENAME_LEN-1:0] path;

  initial begin
    if (!$value$plusargs("IMEM=%s", path)) path = MEM_FILE;
    $display("[IMEM] loading: %s", path);
    $readmemh(path, rom);
  end

  assign o_rdata = rom[i_addr[31:2]];
endmodule
