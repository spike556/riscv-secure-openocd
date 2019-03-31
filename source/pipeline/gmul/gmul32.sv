
module gmul32
(
      input     logic        clk,
      input     logic        rst_n,
      input     logic        req,
      input     logic [31:0] a,
      input     logic [31:0] b,
      input     logic [31:0] m,
      output    logic [31:0] p,
      output    logic        rdy
);

logic [1:0]           state;
logic [1:0]           state_new;
logic [7:0]           bIter;
logic [31:0]          pIter;
logic [31:0]          pIterReg1;
logic [31:0]          pIterReg2;
logic [31:0]          pIterReg3;
logic [31:0]          pIterOut1;
logic [31:0]          pIterOut2;
logic [31:0]          pIterOut3;

always_comb begin
    if (req) begin
        state_new = state + 1;
    end else begin
        state_new = 2'b0;
    end
end
always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <=  2'b0;
    end else begin
        state <= state_new;
    end
end
always_comb begin
    case (state)
        2'b00  : bIter = b[31:24];
        2'b01  : bIter = b[23:16];
        2'b10  : bIter = b[15:8];
        2'b11  : bIter = b[7:0];
    endcase
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pIterReg1 <=  32'b0;
    end else if (req) begin
        case (state)
            2'b00 :   pIterReg1 <=  pIter;
            2'b01,
            2'b10 :   pIterReg1 <=  pIterOut1;
            2'b11 :   begin  end
        endcase
    end
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pIterReg2 <=  32'b0;
    end else if (req) begin
        case (state)
            2'b00 :   begin  end
            2'b01 :   pIterReg2 <=  pIter;
            2'b10 :   pIterReg2 <=  pIterOut2;
            2'b11 :   begin  end
        endcase
    end
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pIterReg3 <=  32'b0;
    end else if (req) begin
        case (state)
            2'b00,
            2'b01 :   begin  end
            2'b10 :   pIterReg3 <=  pIter;
            2'b11 :   begin  end
        endcase
    end
end

mul256 #(
    .DWIDTH(32)
) mul256_i1
(
    .a(pIterReg1),
    .m(m),
    .p(pIterOut1)
);

mul256 #(
    .DWIDTH(32)
) mul256_i2
(
    .a(pIterReg2),
    .m(m),
    .p(pIterOut2)
);

mul256 #(
    .DWIDTH(32)
) mul256_i3
(
    .a(pIterReg3),
    .m(m),
    .p(pIterOut3)
);

gmul_primitive #(
    .DWIDTH(32)
) gmul_primitive_i
(
  .a    (a),
  .b    (bIter),
  .m    (m),
  .p    (pIter)
);
assign rdy = state == 2'b11;
assign p = pIter ^ pIterOut3 ^ pIterOut2 ^ pIterOut1;

endmodule
