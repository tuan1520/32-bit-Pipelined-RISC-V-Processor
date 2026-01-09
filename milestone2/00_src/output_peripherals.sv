// - Decode theo page [31:12]
// - Ghi SB/SH/SW dùng store_merge không shift
// - Đọc trả 32-bit word; cắt/extend đã xử ở LSU

module output_peripherals(
  input  logic        i_clk,
  input  logic        i_rstn,
  input  logic        i_we,
  input  logic [31:0] i_sw,
  input  logic [31:0] i_addr,
  input  logic [31:0] i_wdata,
  input  logic [2:0]  i_size,   // 0=BYTE,1=HALF,2=WORD
  output logic [31:0] o_rdata,
  output logic [6:0]  o_hex0, o_hex1, o_hex2, o_hex3, o_hex4, o_hex5, o_hex6, o_hex7,
  output logic [9:0]  o_ledr,
  output logic [7:0]  o_ledg,
  output logic [31:0] o_lcd
);
  // Registers
  logic [31:0] r_hex_lo, r_hex_hi;
  logic [31:0] r_ledr32, r_ledg32;
  logic [31:0] r_lcd;

  // Page base
  localparam [31:0] BASE_LEDR   = `BASE_LEDR;
  localparam [31:0] BASE_LEDG   = `BASE_LEDG;
  localparam [31:0] BASE_HEX_LO = `BASE_HEX_LO;
  localparam [31:0] BASE_HEX_HI = `BASE_HEX_HI;
  localparam [31:0] BASE_LCD    = `BASE_LCD;

  // Page hit
  localparam [31:0] PAGE_MASK = 32'hFFFF_F000;

  wire hit_ledr   = ((i_addr & PAGE_MASK) == `BASE_LEDR);
  wire hit_ledg   = ((i_addr & PAGE_MASK) == `BASE_LEDG);
  wire hit_hex_lo = ((i_addr & PAGE_MASK) == `BASE_HEX_LO);
  wire hit_hex_hi = ((i_addr & PAGE_MASK) == `BASE_HEX_HI);
  wire hit_lcd    = ((i_addr & PAGE_MASK) == `BASE_LCD);
  wire hit_sw     = ((i_addr & PAGE_MASK) == `BASE_SW);

  // Byte offset
  wire [1:0] ofs = i_addr[1:0];

  // store_merge NO-SHIFT
  function automatic [31:0] store_merge(
    input [31:0] oldw, input [31:0] wd, input [2:0] size, input [1:0] ofs
  );
    logic [31:0] mask, data;
    begin
      unique case (size)
        3'd0: begin // SB
          unique case (ofs)
            2'd0: begin mask=32'h000000FF; data={24'd0,wd[7:0]}; end
            2'd1: begin mask=32'h0000FF00; data={16'd0,wd[7:0],8'd0}; end
            2'd2: begin mask=32'h00FF0000; data={8'd0,wd[7:0],16'd0}; end
            default: begin mask=32'hFF000000; data={wd[7:0],24'd0}; end
          endcase
        end
        3'd1: begin // SH (ofs[1])
          if (ofs[1]==1'b0) begin
            mask=32'h0000FFFF; data={16'd0,wd[15:0]};
          end else begin
            mask=32'hFFFF0000; data={wd[15:0],16'd0};
          end
        end
        default: begin // SW
          mask=32'hFFFF_FFFF; data=wd;
        end
      endcase
      store_merge = (oldw & ~mask) | (data & mask);
    end
  endfunction

  // Writes
    always_ff @(posedge i_clk) begin
    if (!i_rstn) begin
      r_hex_lo  <= 32'd0;
      r_hex_hi  <= 32'd0;
      r_ledr32  <= 32'd0;
      r_ledg32  <= 32'd0;
      r_lcd     <= 32'd0;
    end else if (i_we) begin
      if (hit_ledr)   r_ledr32 <= store_merge(r_ledr32, i_wdata, i_size, ofs);
      if (hit_ledg)   r_ledg32 <= store_merge(r_ledg32, i_wdata, i_size, ofs);
      if (hit_hex_lo) r_hex_lo <= store_merge(r_hex_lo, i_wdata, i_size, ofs);
      if (hit_hex_hi) r_hex_hi <= store_merge(r_hex_hi, i_wdata, i_size, ofs);
      if (hit_lcd)    r_lcd    <= store_merge(r_lcd,    i_wdata, i_size, ofs);
    end
  end

  // Reads (word-level)
  always_comb begin
    unique case (1'b1)
      hit_ledr:   o_rdata = r_ledr32;
      hit_ledg:   o_rdata = r_ledg32;
      hit_hex_lo: o_rdata = r_hex_lo;
      hit_hex_hi: o_rdata = r_hex_hi;
      hit_lcd:    o_rdata = r_lcd;
      hit_sw:     o_rdata = i_sw;
      default:    o_rdata = 32'd0;
    endcase
  end

  // Physical pins (chẻ nibbles -> 7-seg decoder ở chỗ khác nếu có)
  assign {o_hex3,o_hex2,o_hex1,o_hex0} = {r_hex_lo[27:21],r_hex_lo[20:14],r_hex_lo[13:7],r_hex_lo[6:0]};
  assign {o_hex7,o_hex6,o_hex5,o_hex4} = {r_hex_hi[27:21],r_hex_hi[20:14],r_hex_hi[13:7],r_hex_hi[6:0]};
  assign o_ledr = r_ledr32[9:0];
  assign o_ledg = r_ledg32[7:0];
  assign o_lcd  = r_lcd;
endmodule
