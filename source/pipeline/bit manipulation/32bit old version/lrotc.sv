// LROTC
// input : popcnt
// output: configuration bit
// Author: Guozhu Xin
// Date: 2018/5/21

module lrotc
(
    input  logic         pcnt0,
    input  logic [1:0]   pcnt1,
    input  logic         pcnt2,
    input  logic [2:0]   pcnt3,
    input  logic         pcnt4,
    input  logic [1:0]   pcnt5,
    input  logic         pcnt6,
    input  logic [3:0]   pcnt7,
    input  logic         pcnt8,
    input  logic [1:0]   pcnt9,
    input  logic         pcnt10,
    input  logic [2:0]   pcnt11,
    input  logic         pcnt12,
    input  logic [1:0]   pcnt13,
    input  logic         pcnt14,
    input  logic [4:0]   pcnt15,
    input  logic         pcnt16,
    input  logic [1:0]   pcnt17,
    input  logic         pcnt18,
    input  logic [2:0]   pcnt19,
    input  logic         pcnt20,
    input  logic [1:0]   pcnt21,
    input  logic         pcnt22,
    input  logic [3:0]   pcnt23,
    input  logic         pcnt24,
    input  logic [1:0]   pcnt25,
    input  logic         pcnt26,
    input  logic [2:0]   pcnt27,
    input  logic         pcnt28,
    input  logic [1:0]   pcnt29,
    input  logic         pcnt30,
    output logic [15:0]  ibfly_cfg0,              // stage1
    output logic [15:0]  ibfly_cfg1,
    output logic [15:0]  ibfly_cfg2,
    output logic [15:0]  ibfly_cfg3,
    output logic [15:0]  ibfly_cfg4
);

// cfg4
// barrel rotator
logic [15:0] cfg4_temp0;
logic [15:0] cfg4_temp1;
logic [15:0] cfg4_temp2;
logic [15:0] cfg4_temp3;
logic [15:0] cfg4_temp4;

always_comb begin
    case(pcnt15[0])
        1'b0  : cfg4_temp0 = 16'hffff;
        1'b1  : cfg4_temp0 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt15[1])
        1'b0  : cfg4_temp1 = cfg4_temp0;
        1'b1  : cfg4_temp1 = {cfg4_temp0[13:0], ~cfg4_temp0[15:14]};
    endcase
end
always_comb begin
    case(pcnt15[2])
        1'b0  : cfg4_temp2 = cfg4_temp1;
        1'b1  : cfg4_temp2 = {cfg4_temp1[11:0], ~cfg4_temp1[15:12]};
    endcase
end
always_comb begin
    case(pcnt15[3])
        1'b0  : cfg4_temp3 = cfg4_temp2;
        1'b1  : cfg4_temp3 = {cfg4_temp2[7:0], ~cfg4_temp2[15:8]};
    endcase
end
always_comb begin
    case(pcnt15[4])
        1'b0  : cfg4_temp4 = cfg4_temp3;
        1'b1  : cfg4_temp4 = ~cfg4_temp3;
    endcase
end
assign ibfly_cfg4 = cfg4_temp4;

// cfg3
logic [7:0] cfg3_temp00;
logic [7:0] cfg3_temp01;
logic [7:0] cfg3_temp02;
logic [7:0] cfg3_temp03;
always_comb begin
    case(pcnt7[0])
        1'b0  : cfg3_temp00 = 8'hff;
        1'b1  : cfg3_temp00 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt7[1])
        1'b0  : cfg3_temp01 = cfg3_temp00;
        1'b1  : cfg3_temp01 = {cfg3_temp00[5:0], ~cfg3_temp00[7:6]};
    endcase
end
always_comb begin
    case(pcnt7[2])
        1'b0  : cfg3_temp02 = cfg3_temp01;
        1'b1  : cfg3_temp02 = {cfg3_temp01[3:0], ~cfg3_temp01[7:4]};
    endcase
end
always_comb begin
    case(pcnt7[3])
        1'b0  : cfg3_temp03 = cfg3_temp02;
        1'b1  : cfg3_temp03 = ~cfg3_temp02;
    endcase
end

logic [7:0] cfg3_temp10;
logic [7:0] cfg3_temp11;
logic [7:0] cfg3_temp12;
logic [7:0] cfg3_temp13;
always_comb begin
    case(pcnt23[0])
        1'b0  : cfg3_temp10 = 8'hff;
        1'b1  : cfg3_temp10 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt23[1])
        1'b0  : cfg3_temp11 = cfg3_temp10;
        1'b1  : cfg3_temp11 = {cfg3_temp10[5:0], ~cfg3_temp10[7:6]};
    endcase
end
always_comb begin
    case(pcnt23[2])
        1'b0  : cfg3_temp12 = cfg3_temp11;
        1'b1  : cfg3_temp12 = {cfg3_temp11[3:0], ~cfg3_temp11[7:4]};
    endcase
end
always_comb begin
    case(pcnt23[3])
        1'b0  : cfg3_temp13 = cfg3_temp12;
        1'b1  : cfg3_temp13 = ~cfg3_temp12;
    endcase
end
assign ibfly_cfg3 = {cfg3_temp13, cfg3_temp03};

// cfg2
logic [3:0] cfg2_temp00;
logic [3:0] cfg2_temp01;
logic [3:0] cfg2_temp02;
always_comb begin
    case(pcnt3[0])
        1'b0  : cfg2_temp00 = 4'hf;
        1'b1  : cfg2_temp00 = 4'he;
    endcase
end
always_comb begin
    case(pcnt3[1])
        1'b0  : cfg2_temp01 = cfg2_temp00;
        1'b1  : cfg2_temp01 = {cfg2_temp00[1:0], ~cfg2_temp00[3:2]};
    endcase
end
always_comb begin
    case(pcnt3[2])
        1'b0  : cfg2_temp02 = cfg2_temp01;
        1'b1  : cfg2_temp02 = ~cfg2_temp01;
    endcase
end

logic [3:0] cfg2_temp10;
logic [3:0] cfg2_temp11;
logic [3:0] cfg2_temp12;
always_comb begin
    case(pcnt11[0])
        1'b0  : cfg2_temp10 = 4'hf;
        1'b1  : cfg2_temp10 = 4'he;
    endcase
end
always_comb begin
    case(pcnt11[1])
        1'b0  : cfg2_temp11 = cfg2_temp10;
        1'b1  : cfg2_temp11 = {cfg2_temp10[1:0], ~cfg2_temp10[3:2]};
    endcase
end
always_comb begin
    case(pcnt11[2])
        1'b0  : cfg2_temp12 = cfg2_temp11;
        1'b1  : cfg2_temp12 = ~cfg2_temp11;
    endcase
end

logic [3:0] cfg2_temp20;
logic [3:0] cfg2_temp21;
logic [3:0] cfg2_temp22;
always_comb begin
    case(pcnt19[0])
        1'b0  : cfg2_temp20 = 4'hf;
        1'b1  : cfg2_temp20 = 4'he;
    endcase
end
always_comb begin
    case(pcnt19[1])
        1'b0  : cfg2_temp21 = cfg2_temp20;
        1'b1  : cfg2_temp21 = {cfg2_temp20[1:0], ~cfg2_temp20[3:2]};
    endcase
end
always_comb begin
    case(pcnt19[2])
        1'b0  : cfg2_temp22 = cfg2_temp21;
        1'b1  : cfg2_temp22 = ~cfg2_temp21;
    endcase
end

logic [3:0] cfg2_temp30;
logic [3:0] cfg2_temp31;
logic [3:0] cfg2_temp32;
always_comb begin
    case(pcnt27[0])
        1'b0  : cfg2_temp30 = 4'hf;
        1'b1  : cfg2_temp30 = 4'he;
    endcase
end
always_comb begin
    case(pcnt27[1])
        1'b0  : cfg2_temp31 = cfg2_temp30;
        1'b1  : cfg2_temp31 = {cfg2_temp30[1:0], ~cfg2_temp30[3:2]};
    endcase
end
always_comb begin
    case(pcnt27[2])
        1'b0  : cfg2_temp32 = cfg2_temp31;
        1'b1  : cfg2_temp32 = ~cfg2_temp31;
    endcase
end
assign ibfly_cfg2 = {cfg2_temp32, cfg2_temp22, cfg2_temp12, cfg2_temp02};

// cfg 1
logic [1:0] cfg1_temp00;
logic [1:0] cfg1_temp01;
always_comb begin
    case(pcnt1[0])
        1'b0  : cfg1_temp00 = 2'b11;
        1'b1  : cfg1_temp00 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt1[1])
        1'b0  : cfg1_temp01 = cfg1_temp00;
        1'b1  : cfg1_temp01 = ~cfg1_temp00;
    endcase
end

logic [1:0] cfg1_temp10;
logic [1:0] cfg1_temp11;
always_comb begin
    case(pcnt5[0])
        1'b0  : cfg1_temp10 = 2'b11;
        1'b1  : cfg1_temp10 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt5[1])
        1'b0  : cfg1_temp11 = cfg1_temp10;
        1'b1  : cfg1_temp11 = ~cfg1_temp10;
    endcase
end

logic [1:0] cfg1_temp20;
logic [1:0] cfg1_temp21;
always_comb begin
    case(pcnt9[0])
        1'b0  : cfg1_temp20 = 2'b11;
        1'b1  : cfg1_temp20 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt9[1])
        1'b0  : cfg1_temp21 = cfg1_temp20;
        1'b1  : cfg1_temp21 = ~cfg1_temp20;
    endcase
end

logic [1:0] cfg1_temp30;
logic [1:0] cfg1_temp31;
always_comb begin
    case(pcnt13[0])
        1'b0  : cfg1_temp30 = 2'b11;
        1'b1  : cfg1_temp30 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt13[1])
        1'b0  : cfg1_temp31 = cfg1_temp30;
        1'b1  : cfg1_temp31 = ~cfg1_temp30;
    endcase
end

logic [1:0] cfg1_temp40;
logic [1:0] cfg1_temp41;
always_comb begin
    case(pcnt17[0])
        1'b0  : cfg1_temp40 = 2'b11;
        1'b1  : cfg1_temp40 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt17[1])
        1'b0  : cfg1_temp41 = cfg1_temp40;
        1'b1  : cfg1_temp41 = ~cfg1_temp40;
    endcase
end

logic [1:0] cfg1_temp50;
logic [1:0] cfg1_temp51;
always_comb begin
    case(pcnt21[0])
        1'b0  : cfg1_temp50 = 2'b11;
        1'b1  : cfg1_temp50 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt21[1])
        1'b0  : cfg1_temp51 = cfg1_temp50;
        1'b1  : cfg1_temp51 = ~cfg1_temp50;
    endcase
end

logic [1:0] cfg1_temp60;
logic [1:0] cfg1_temp61;
always_comb begin
    case(pcnt25[0])
        1'b0  : cfg1_temp60 = 2'b11;
        1'b1  : cfg1_temp60 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt25[1])
        1'b0  : cfg1_temp61 = cfg1_temp60;
        1'b1  : cfg1_temp61 = ~cfg1_temp60;
    endcase
end

logic [1:0] cfg1_temp70;
logic [1:0] cfg1_temp71;
always_comb begin
    case(pcnt29[0])
        1'b0  : cfg1_temp70 = 2'b11;
        1'b1  : cfg1_temp70 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt29[1])
        1'b0  : cfg1_temp71 = cfg1_temp70;
        1'b1  : cfg1_temp71 = ~cfg1_temp70;
    endcase
end
assign ibfly_cfg1 = {cfg1_temp71, cfg1_temp61, cfg1_temp51, cfg1_temp41,
                     cfg1_temp31, cfg1_temp21, cfg1_temp11, cfg1_temp01};

// cfg 0
assign ibfly_cfg0[0] = ~pcnt0;
assign ibfly_cfg0[1] = ~pcnt2;
assign ibfly_cfg0[2] = ~pcnt4;
assign ibfly_cfg0[3] = ~pcnt6;
assign ibfly_cfg0[4] = ~pcnt8;
assign ibfly_cfg0[5] = ~pcnt10;
assign ibfly_cfg0[6] = ~pcnt12;
assign ibfly_cfg0[7] = ~pcnt14;
assign ibfly_cfg0[8] = ~pcnt16;
assign ibfly_cfg0[9] = ~pcnt18;
assign ibfly_cfg0[10] = ~pcnt20;
assign ibfly_cfg0[11] = ~pcnt22;
assign ibfly_cfg0[12] = ~pcnt24;
assign ibfly_cfg0[13] = ~pcnt26;
assign ibfly_cfg0[14] = ~pcnt28;
assign ibfly_cfg0[15] = ~pcnt30;

endmodule
