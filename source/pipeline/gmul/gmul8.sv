
module gmul8
(
    input     logic [7:0] a,
    input     logic [7:0] b,
    input     logic [7:0] m,
    output    logic [7:0] p
);

gmul_primitive #(
    parameter DWIDTH = 8
) gmul_primitive_i
(
    .*
);

endmodule
