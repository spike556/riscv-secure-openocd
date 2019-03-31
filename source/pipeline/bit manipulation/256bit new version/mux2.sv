// 0:nop   1:swap
module mux2
(
    input   logic        a,
    input   logic        b,
    input   logic        sel,
    output  logic        out1,
    output  logic        out2
);

assign out1 = sel ? b : a;
assign out2 = sel ? a : b;

endmodule
