
module gmul_primitive #(
    parameter DWIDTH = 8
)
(
    input     logic [DWIDTH - 1:0] a,
    input     logic [7:0] b,
    input     logic [DWIDTH - 1:0] m,
    output    logic [DWIDTH - 1:0] p
);

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

logic   [DWIDTH - 1:0]   p0;
logic   [DWIDTH - 1:0]   p1;
logic   [DWIDTH - 1:0]   p2;
logic   [DWIDTH - 1:0]   p3;
logic   [DWIDTH - 1:0]   p4;
logic   [DWIDTH - 1:0]   p5;
logic   [DWIDTH - 1:0]   p6;
logic   [DWIDTH - 1:0]   p7;

logic   [DWIDTH - 1:0]   m2;
logic   [DWIDTH - 1:0]   m4;
logic   [DWIDTH - 1:0]   m8;
logic   [DWIDTH - 1:0]   m16;
logic   [DWIDTH - 1:0]   m32;
logic   [DWIDTH - 1:0]   m64;
logic   [DWIDTH - 1:0]   m128;

assign p0 = {DWIDTH{b[0]}} & a;

assign m2 = mul2(a, m);
assign p1 = {DWIDTH{b[1]}} & m2;

assign m4 = mul2(m2, m);
assign p2 = {DWIDTH{b[2]}} & m4;

assign m8 = mul2(m4, m);
assign p3 = {DWIDTH{b[3]}} & m8;

assign m16 = mul2(m8, m);
assign p4 = {DWIDTH{b[4]}} & m16;

assign m32 = mul2(m16, m);
assign p5 = {DWIDTH{b[5]}} & m32;

assign m64 = mul2(m32, m);
assign p6 = {DWIDTH{b[6]}} & m64;

assign m128 = mul2(m64, m);
assign p7 = {DWIDTH{b[7]}} & m128;

assign p = p0^p1^p2^p3^p4^p5^p6^p7;

endmodule
