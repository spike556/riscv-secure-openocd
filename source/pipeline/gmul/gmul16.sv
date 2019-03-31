
module gmul16
(
    input     logic        clk,
    input     logic        rst_n,
    input     logic        req,
    input     logic [15:0] a,
    input     logic [15:0] b,
    input     logic [15:0] m,
    output    logic [15:0] p,
    output    logic        rdy
);

logic                 state;
logic [7:0]           bIter;
logic [15:0]          pIter;
logic [15:0]          pIterReg;
logic [15:0]          pIterOut;

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <=  1'b0;
    end else begin
        if (req) begin
            state <= ~state;
        end else begin
            state <= 1'b0;
        end
    end
end
always_comb begin
    case (state)
        1'b0  : bIter = b[15:8];
        1'b1  : bIter = b[7:0];
    endcase
end

always_ff @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pIterReg <=  16'b0;
    end else if (req & ~state) begin
        pIterReg  <=  pIter;
    end
end

mul256 #(
    .DWIDTH(16)
) mul256_i
(
    .a(pIterReg),
    .m(m),
    .p(pIterOut)
);

gmul_primitive #(
    .DWIDTH(16)
) gmul_primitive_i
(
  .a    (a),
  .b    (bIter),
  .m    (m),
  .p    (pIter)
);
assign rdy = state;
assign p = pIterOut ^ pIter;

endmodule
