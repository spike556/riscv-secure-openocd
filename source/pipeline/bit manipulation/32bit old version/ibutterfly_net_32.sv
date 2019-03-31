// ibutterfly network
// Author: Guozhu Xin
// Date:   2018/05/20

module ibutterfly_net_32
(
    input   logic [15:0]    cfg0,
    input   logic [15:0]    cfg1,
    input   logic [15:0]    cfg2,
    input   logic [15:0]    cfg3,
    input   logic [15:0]    cfg4,
    input   logic [31:0]    data_in,
    output  logic [31:0]    data_out
);

logic [31:0]    data_stage1;
logic [31:0]    data_stage2;
logic [31:0]    data_stage3;
logic [31:0]    data_stage4;

// stage 1
genvar i;
generate
    for (i = 0; i < 32; i = i + 2) begin  : stage1_proc
        mux2 mux2_i(
            .a    (data_in[i]),
            .b    (data_in[i+1]),
            .sel  (cfg0[i/2]),
            .out1 (data_stage1[i]),
            .out2 (data_stage1[i+1])
          );
    end
endgenerate

// stage 2
generate
    for (i = 0; i < 32; i = i + 4) begin  : stage2_proc
        mux2 mux2_i1(
            .a    (data_stage1[i]),
            .b    (data_stage1[i+2]),
            .sel  (cfg1[i/2]),
            .out1 (data_stage2[i]),
            .out2 (data_stage2[i+2])
          );
        mux2 mux2_i2(
            .a    (data_stage1[i+1]),
            .b    (data_stage1[i+3]),
            .sel  (cfg1[i/2+1]),
            .out1 (data_stage2[i+1]),
            .out2 (data_stage2[i+3])
          );
    end
endgenerate

// stage 3
generate
    for (i = 0; i < 32; i = i + 8) begin  : stage3_proc
        mux2 mux2_i1(
            .a    (data_stage2[i]),
            .b    (data_stage2[i+4]),
            .sel  (cfg2[i/2]),
            .out1 (data_stage3[i]),
            .out2 (data_stage3[i+4])
          );
        mux2 mux2_i2(
            .a    (data_stage2[i+1]),
            .b    (data_stage2[i+5]),
            .sel  (cfg2[i/2+1]),
            .out1 (data_stage3[i+1]),
            .out2 (data_stage3[i+5])
          );
        mux2 mux2_i3(
            .a    (data_stage2[i+2]),
            .b    (data_stage2[i+6]),
            .sel  (cfg2[i/2+2]),
            .out1 (data_stage3[i+2]),
            .out2 (data_stage3[i+6])
          );
        mux2 mux2_i4(
            .a    (data_stage2[i+3]),
            .b    (data_stage2[i+7]),
            .sel  (cfg2[i/2+3]),
            .out1 (data_stage3[i+3]),
            .out2 (data_stage3[i+7])
          );
    end
endgenerate

// stage 4
generate
    for (i = 0; i < 32; i = i + 16) begin  : stage4_proc
        mux2 mux2_i1(
            .a    (data_stage3[i]),
            .b    (data_stage3[i+8]),
            .sel  (cfg3[i/2]),
            .out1 (data_stage4[i]),
            .out2 (data_stage4[i+8])
          );
        mux2 mux2_i2(
            .a    (data_stage3[i+1]),
            .b    (data_stage3[i+9]),
            .sel  (cfg3[i/2+1]),
            .out1 (data_stage4[i+1]),
            .out2 (data_stage4[i+9])
          );
        mux2 mux2_i3(
            .a    (data_stage3[i+2]),
            .b    (data_stage3[i+10]),
            .sel  (cfg3[i/2+2]),
            .out1 (data_stage4[i+2]),
            .out2 (data_stage4[i+10])
          );
        mux2 mux2_i4(
            .a    (data_stage3[i+3]),
            .b    (data_stage3[i+11]),
            .sel  (cfg3[i/2+3]),
            .out1 (data_stage4[i+3]),
            .out2 (data_stage4[i+11])
          );
        mux2 mux2_i5(
            .a    (data_stage3[i+4]),
            .b    (data_stage3[i+12]),
            .sel  (cfg3[i/2+4]),
            .out1 (data_stage4[i+4]),
            .out2 (data_stage4[i+12])
          );
        mux2 mux2_i6(
            .a    (data_stage3[i+5]),
            .b    (data_stage3[i+13]),
            .sel  (cfg3[i/2+5]),
            .out1 (data_stage4[i+5]),
            .out2 (data_stage4[i+13])
          );
        mux2 mux2_i7(
            .a    (data_stage3[i+6]),
            .b    (data_stage3[i+14]),
            .sel  (cfg3[i/2+6]),
            .out1 (data_stage4[i+6]),
            .out2 (data_stage4[i+14])
          );
        mux2 mux2_i8(
            .a    (data_stage3[i+7]),
            .b    (data_stage3[i+15]),
            .sel  (cfg3[i/2+7]),
            .out1 (data_stage4[i+7]),
            .out2 (data_stage4[i+15])
          );
    end
endgenerate

// stage 5
generate
    for (i = 0; i < 16; i = i + 1) begin  : stage5_proc
        mux2 mux2_i(
            .a    (data_stage4[i]),
            .b    (data_stage4[i+16]),
            .sel  (cfg4[i]),
            .out1 (data_out[i]),
            .out2 (data_out[i+16])
          );
    end
endgenerate

endmodule
