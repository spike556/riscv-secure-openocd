// ibutterfly network
// Author: Guozhu Xin
// Date:   2018/06/06

module ibutterfly_net_256
(
    input   logic [127:0]    cfg0,
    input   logic [127:0]    cfg1,
    input   logic [127:0]    cfg2,
    input   logic [127:0]    cfg3,
    input   logic [127:0]    cfg4,
    input   logic [127:0]    cfg5,
    input   logic [127:0]    cfg6,
    input   logic [127:0]    cfg7,
    input   logic [255:0]   data_in,
    output  logic [255:0]   data_out
);

logic [255:0]    data_stage1;
logic [255:0]    data_stage2;
logic [255:0]    data_stage3;
logic [255:0]    data_stage4;
logic [255:0]    data_stage5;
logic [255:0]    data_stage6;
logic [255:0]    data_stage7;

// stage 1
genvar i;
generate
    for (i = 0; i < 256; i = i + 2) begin  : stage1_proc
        mux2 mux2_i10(
            .a    (data_in[i]),
            .b    (data_in[i+1]),
            .sel  (cfg0[i/2]),
            .out1 (data_stage1[i]),
            .out2 (data_stage1[i+1])
          );
    end : stage1_proc
endgenerate

// stage 2
generate
    for (i = 0; i < 256; i = i + 4) begin  : stage2_proc
        mux2 mux2_i21(
            .a    (data_stage1[i]),
            .b    (data_stage1[i+2]),
            .sel  (cfg1[i/2]),
            .out1 (data_stage2[i]),
            .out2 (data_stage2[i+2])
          );
        mux2 mux2_i22(
            .a    (data_stage1[i+1]),
            .b    (data_stage1[i+3]),
            .sel  (cfg1[i/2+1]),
            .out1 (data_stage2[i+1]),
            .out2 (data_stage2[i+3])
          );
    end : stage2_proc
endgenerate

// stage 3
generate
    for (i = 0; i < 256; i = i + 8) begin  : stage3_proc
        mux2 mux2_i31(
            .a    (data_stage2[i]),
            .b    (data_stage2[i+4]),
            .sel  (cfg2[i/2]),
            .out1 (data_stage3[i]),
            .out2 (data_stage3[i+4])
          );
        mux2 mux2_i32(
            .a    (data_stage2[i+1]),
            .b    (data_stage2[i+5]),
            .sel  (cfg2[i/2+1]),
            .out1 (data_stage3[i+1]),
            .out2 (data_stage3[i+5])
          );
        mux2 mux2_i33(
            .a    (data_stage2[i+2]),
            .b    (data_stage2[i+6]),
            .sel  (cfg2[i/2+2]),
            .out1 (data_stage3[i+2]),
            .out2 (data_stage3[i+6])
          );
        mux2 mux2_i34(
            .a    (data_stage2[i+3]),
            .b    (data_stage2[i+7]),
            .sel  (cfg2[i/2+3]),
            .out1 (data_stage3[i+3]),
            .out2 (data_stage3[i+7])
          );
    end : stage3_proc
endgenerate

// stage 4
generate
    for (i = 0; i < 256; i = i + 16) begin  : stage4_proc
        mux2 mux2_i41(
            .a    (data_stage3[i]),
            .b    (data_stage3[i+8]),
            .sel  (cfg3[i/2]),
            .out1 (data_stage4[i]),
            .out2 (data_stage4[i+8])
          );
        mux2 mux2_i42(
            .a    (data_stage3[i+1]),
            .b    (data_stage3[i+9]),
            .sel  (cfg3[i/2+1]),
            .out1 (data_stage4[i+1]),
            .out2 (data_stage4[i+9])
          );
        mux2 mux2_i43(
            .a    (data_stage3[i+2]),
            .b    (data_stage3[i+10]),
            .sel  (cfg3[i/2+2]),
            .out1 (data_stage4[i+2]),
            .out2 (data_stage4[i+10])
          );
        mux2 mux2_i44(
            .a    (data_stage3[i+3]),
            .b    (data_stage3[i+11]),
            .sel  (cfg3[i/2+3]),
            .out1 (data_stage4[i+3]),
            .out2 (data_stage4[i+11])
          );
        mux2 mux2_i45(
            .a    (data_stage3[i+4]),
            .b    (data_stage3[i+12]),
            .sel  (cfg3[i/2+4]),
            .out1 (data_stage4[i+4]),
            .out2 (data_stage4[i+12])
          );
        mux2 mux2_i46(
            .a    (data_stage3[i+5]),
            .b    (data_stage3[i+13]),
            .sel  (cfg3[i/2+5]),
            .out1 (data_stage4[i+5]),
            .out2 (data_stage4[i+13])
          );
        mux2 mux2_i47(
            .a    (data_stage3[i+6]),
            .b    (data_stage3[i+14]),
            .sel  (cfg3[i/2+6]),
            .out1 (data_stage4[i+6]),
            .out2 (data_stage4[i+14])
          );
        mux2 mux2_i48(
            .a    (data_stage3[i+7]),
            .b    (data_stage3[i+15]),
            .sel  (cfg3[i/2+7]),
            .out1 (data_stage4[i+7]),
            .out2 (data_stage4[i+15])
          );
    end : stage4_proc
endgenerate

// stage 5
generate
    for (i = 0; i < 16; i = i + 1) begin  : stage5_proc
        mux2 mux2_i51(
            .a    (data_stage4[i]),
            .b    (data_stage4[i+16]),
            .sel  (cfg4[i]),
            .out1 (data_stage5[i]),
            .out2 (data_stage5[i+16])
          );
        mux2 mux2_i52(
            .a    (data_stage4[i+32]),
            .b    (data_stage4[i+48]),
            .sel  (cfg4[i+16]),
            .out1 (data_stage5[i+32]),
            .out2 (data_stage5[i+48])
          );
        mux2 mux2_i53(
            .a    (data_stage4[i+64]),
            .b    (data_stage4[i+80]),
            .sel  (cfg4[i+32]),
            .out1 (data_stage5[i+64]),
            .out2 (data_stage5[i+80])
          );
        mux2 mux2_i54(
            .a    (data_stage4[i+96]),
            .b    (data_stage4[i+112]),
            .sel  (cfg4[i+48]),
            .out1 (data_stage5[i+96]),
            .out2 (data_stage5[i+112])
          );
        mux2 mux2_i55(
            .a    (data_stage4[i+128]),
            .b    (data_stage4[i+144]),
            .sel  (cfg4[i+64]),
            .out1 (data_stage5[i+128]),
            .out2 (data_stage5[i+144])
          );
        mux2 mux2_i56(
            .a    (data_stage4[i+160]),
            .b    (data_stage4[i+176]),
            .sel  (cfg4[i+80]),
            .out1 (data_stage5[i+160]),
            .out2 (data_stage5[i+176])
          );
        mux2 mux2_i57(
            .a    (data_stage4[i+192]),
            .b    (data_stage4[i+208]),
            .sel  (cfg4[i+96]),
            .out1 (data_stage5[i+192]),
            .out2 (data_stage5[i+208])
          );
        mux2 mux2_i58(
            .a    (data_stage4[i+224]),
            .b    (data_stage4[i+240]),
            .sel  (cfg4[i+112]),
            .out1 (data_stage5[i+224]),
            .out2 (data_stage5[i+240])
          );
    end : stage5_proc
endgenerate

// stage 6
generate
    for (i = 0; i < 32; i = i + 1) begin  : stage6_proc
        mux2 mux2_i61(
            .a    (data_stage5[i]),
            .b    (data_stage5[i+32]),
            .sel  (cfg5[i]),
            .out1 (data_stage6[i]),
            .out2 (data_stage6[i+32])
          );
        mux2 mux2_i62(
            .a    (data_stage5[i+64]),
            .b    (data_stage5[i+96]),
            .sel  (cfg5[i+32]),
            .out1 (data_stage6[i+64]),
            .out2 (data_stage6[i+96])
          );
        mux2 mux2_i63(
            .a    (data_stage5[i+128]),
            .b    (data_stage5[i+160]),
            .sel  (cfg5[i+64]),
            .out1 (data_stage6[i+128]),
            .out2 (data_stage6[i+160])
          );
        mux2 mux2_i64(
            .a    (data_stage5[i+192]),
            .b    (data_stage5[i+224]),
            .sel  (cfg5[i+96]),
            .out1 (data_stage6[i+192]),
            .out2 (data_stage6[i+224])
          );
    end : stage6_proc
endgenerate

// stage 7
generate
    for (i = 0; i < 64; i = i + 1) begin  : stage7_proc
        mux2 mux2_i71(
            .a    (data_stage6[i]),
            .b    (data_stage6[i+64]),
            .sel  (cfg6[i]),
            .out1 (data_stage7[i]),
            .out2 (data_stage7[i+64])
          );
        mux2 mux2_i72(
            .a    (data_stage6[i+128]),
            .b    (data_stage6[i+192]),
            .sel  (cfg6[i+64]),
            .out1 (data_stage7[i+128]),
            .out2 (data_stage7[i+192])
          );
    end : stage7_proc
endgenerate

// stage 8
generate
    for (i = 0; i < 128; i = i + 1) begin  : stage8_proc
        mux2 mux2_i81(
            .a    (data_stage7[i]),
            .b    (data_stage7[i+128]),
            .sel  (cfg7[i]),
            .out1 (data_out[i]),
            .out2 (data_out[i+128])
          );
    end : stage8_proc
endgenerate

endmodule
