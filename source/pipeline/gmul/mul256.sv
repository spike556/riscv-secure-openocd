module mul256 #(
    parameter DWIDTH = 8
)
(
    input     logic [DWIDTH - 1:0] a,
    input     logic [DWIDTH - 1:0] m,
    output    logic [DWIDTH - 1:0] p
);
logic   [DWIDTH - 1:0]   m2;
logic   [DWIDTH - 1:0]   m4;
logic   [DWIDTH - 1:0]   m8;
logic   [DWIDTH - 1:0]   m16;
logic   [DWIDTH - 1:0]   m32;
logic   [DWIDTH - 1:0]   m64;
logic   [DWIDTH - 1:0]   m128;
logic   [DWIDTH - 1:0]   m256;

function logic [DWIDTH - 1:0]  mul2 (
    input   logic [DWIDTH - 1:0]  a,
    input   logic [DWIDTH - 1:0]  m
);
    logic         [DWIDTH - 1:0] out;
begin
    out = {a[DWIDTH - 2:0], 1'b0} ^ (m & {DWIDTH{a[DWIDTH - 1]}});
    return out;
end
endfunction : mul2

assign m2 = mul2(a, m);

assign m4 = mul2(m2, m);

assign m8 = mul2(m4, m);

assign m16 = mul2(m8, m);

assign m32 = mul2(m16, m);

assign m64 = mul2(m32, m);

assign m128 = mul2(m64, m);

assign m256 = mul2(m128, m);

assign p = m256;

endmodule
