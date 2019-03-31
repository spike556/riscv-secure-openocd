// LROTC
// input : popcnt
// output: configuration bit
// Author: Guozhu Xin
// Date: 2018/06/06

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
    input  logic [5:0]   pcnt31,
    input  logic         pcnt32,
    input  logic [1:0]   pcnt33,
    input  logic         pcnt34,
    input  logic [2:0]   pcnt35,
    input  logic         pcnt36,
    input  logic [1:0]   pcnt37,
    input  logic         pcnt38,
    input  logic [3:0]   pcnt39,
    input  logic         pcnt40,
    input  logic [1:0]   pcnt41,
    input  logic         pcnt42,
    input  logic [2:0]   pcnt43,
    input  logic         pcnt44,
    input  logic [1:0]   pcnt45,
    input  logic         pcnt46,
    input  logic [4:0]   pcnt47,
    input  logic         pcnt48,
    input  logic [1:0]   pcnt49,
    input  logic         pcnt50,
    input  logic [2:0]   pcnt51,
    input  logic         pcnt52,
    input  logic [1:0]   pcnt53,
    input  logic         pcnt54,
    input  logic [3:0]   pcnt55,
    input  logic         pcnt56,
    input  logic [1:0]   pcnt57,
    input  logic         pcnt58,
    input  logic [2:0]   pcnt59,
    input  logic         pcnt60,
    input  logic [1:0]   pcnt61,
    input  logic         pcnt62,
    input  logic [6:0]   pcnt63,
    input  logic         pcnt64,
    input  logic [1:0]   pcnt65,
    input  logic         pcnt66,
    input  logic [2:0]   pcnt67,
    input  logic         pcnt68,
    input  logic [1:0]   pcnt69,
    input  logic         pcnt70,
    input  logic [3:0]   pcnt71,
    input  logic         pcnt72,
    input  logic [1:0]   pcnt73,
    input  logic         pcnt74,
    input  logic [2:0]   pcnt75,
    input  logic         pcnt76,
    input  logic [1:0]   pcnt77,
    input  logic         pcnt78,
    input  logic [4:0]   pcnt79,
    input  logic         pcnt80,
    input  logic [1:0]   pcnt81,
    input  logic         pcnt82,
    input  logic [2:0]   pcnt83,
    input  logic         pcnt84,
    input  logic [1:0]   pcnt85,
    input  logic         pcnt86,
    input  logic [3:0]   pcnt87,
    input  logic         pcnt88,
    input  logic [1:0]   pcnt89,
    input  logic         pcnt90,
    input  logic [2:0]   pcnt91,
    input  logic         pcnt92,
    input  logic [1:0]   pcnt93,
    input  logic         pcnt94,
    input  logic [5:0]   pcnt95,
    input  logic         pcnt96,
    input  logic [1:0]   pcnt97,
    input  logic         pcnt98,
    input  logic [2:0]   pcnt99,
    input  logic         pcnt100,
    input  logic [1:0]   pcnt101,
    input  logic         pcnt102,
    input  logic [3:0]   pcnt103,
    input  logic         pcnt104,
    input  logic [1:0]   pcnt105,
    input  logic         pcnt106,
    input  logic [2:0]   pcnt107,
    input  logic         pcnt108,
    input  logic [1:0]   pcnt109,
    input  logic         pcnt110,
    input  logic [4:0]   pcnt111,
    input  logic         pcnt112,
    input  logic [1:0]   pcnt113,
    input  logic         pcnt114,
    input  logic [2:0]   pcnt115,
    input  logic         pcnt116,
    input  logic [1:0]   pcnt117,
    input  logic         pcnt118,
    input  logic [3:0]   pcnt119,
    input  logic         pcnt120,
    input  logic [1:0]   pcnt121,
    input  logic         pcnt122,
    input  logic [2:0]   pcnt123,
    input  logic         pcnt124,
    input  logic [1:0]   pcnt125,
    input  logic         pcnt126,
    input  logic [7:0]   pcnt127,
    input  logic         pcnt128,
    input  logic [1:0]   pcnt129,
    input  logic         pcnt130,
    input  logic [2:0]   pcnt131,
    input  logic         pcnt132,
    input  logic [1:0]   pcnt133,
    input  logic         pcnt134,
    input  logic [3:0]   pcnt135,
    input  logic         pcnt136,
    input  logic [1:0]   pcnt137,
    input  logic         pcnt138,
    input  logic [2:0]   pcnt139,
    input  logic         pcnt140,
    input  logic [1:0]   pcnt141,
    input  logic         pcnt142,
    input  logic [4:0]   pcnt143,
    input  logic         pcnt144,
    input  logic [1:0]   pcnt145,
    input  logic         pcnt146,
    input  logic [2:0]   pcnt147,
    input  logic         pcnt148,
    input  logic [1:0]   pcnt149,
    input  logic         pcnt150,
    input  logic [3:0]   pcnt151,
    input  logic         pcnt152,
    input  logic [1:0]   pcnt153,
    input  logic         pcnt154,
    input  logic [2:0]   pcnt155,
    input  logic         pcnt156,
    input  logic [1:0]   pcnt157,
    input  logic         pcnt158,
    input  logic [5:0]   pcnt159,
    input  logic         pcnt160,
    input  logic [1:0]   pcnt161,
    input  logic         pcnt162,
    input  logic [2:0]   pcnt163,
    input  logic         pcnt164,
    input  logic [1:0]   pcnt165,
    input  logic         pcnt166,
    input  logic [3:0]   pcnt167,
    input  logic         pcnt168,
    input  logic [1:0]   pcnt169,
    input  logic         pcnt170,
    input  logic [2:0]   pcnt171,
    input  logic         pcnt172,
    input  logic [1:0]   pcnt173,
    input  logic         pcnt174,
    input  logic [4:0]   pcnt175,
    input  logic         pcnt176,
    input  logic [1:0]   pcnt177,
    input  logic         pcnt178,
    input  logic [2:0]   pcnt179,
    input  logic         pcnt180,
    input  logic [1:0]   pcnt181,
    input  logic         pcnt182,
    input  logic [3:0]   pcnt183,
    input  logic         pcnt184,
    input  logic [1:0]   pcnt185,
    input  logic         pcnt186,
    input  logic [2:0]   pcnt187,
    input  logic         pcnt188,
    input  logic [1:0]   pcnt189,
    input  logic         pcnt190,
    input  logic [6:0]   pcnt191,
    input  logic         pcnt192,
    input  logic [1:0]   pcnt193,
    input  logic         pcnt194,
    input  logic [2:0]   pcnt195,
    input  logic         pcnt196,
    input  logic [1:0]   pcnt197,
    input  logic         pcnt198,
    input  logic [3:0]   pcnt199,
    input  logic         pcnt200,
    input  logic [1:0]   pcnt201,
    input  logic         pcnt202,
    input  logic [2:0]   pcnt203,
    input  logic         pcnt204,
    input  logic [1:0]   pcnt205,
    input  logic         pcnt206,
    input  logic [4:0]   pcnt207,
    input  logic         pcnt208,
    input  logic [1:0]   pcnt209,
    input  logic         pcnt210,
    input  logic [2:0]   pcnt211,
    input  logic         pcnt212,
    input  logic [1:0]   pcnt213,
    input  logic         pcnt214,
    input  logic [3:0]   pcnt215,
    input  logic         pcnt216,
    input  logic [1:0]   pcnt217,
    input  logic         pcnt218,
    input  logic [2:0]   pcnt219,
    input  logic         pcnt220,
    input  logic [1:0]   pcnt221,
    input  logic         pcnt222,
    input  logic [5:0]   pcnt223,
    input  logic         pcnt224,
    input  logic [1:0]   pcnt225,
    input  logic         pcnt226,
    input  logic [2:0]   pcnt227,
    input  logic         pcnt228,
    input  logic [1:0]   pcnt229,
    input  logic         pcnt230,
    input  logic [3:0]   pcnt231,
    input  logic         pcnt232,
    input  logic [1:0]   pcnt233,
    input  logic         pcnt234,
    input  logic [2:0]   pcnt235,
    input  logic         pcnt236,
    input  logic [1:0]   pcnt237,
    input  logic         pcnt238,
    input  logic [4:0]   pcnt239,
    input  logic         pcnt240,
    input  logic [1:0]   pcnt241,
    input  logic         pcnt242,
    input  logic [2:0]   pcnt243,
    input  logic         pcnt244,
    input  logic [1:0]   pcnt245,
    input  logic         pcnt246,
    input  logic [3:0]   pcnt247,
    input  logic         pcnt248,
    input  logic [1:0]   pcnt249,
    input  logic         pcnt250,
    input  logic [2:0]   pcnt251,
    input  logic         pcnt252,
    input  logic [1:0]   pcnt253,
    input  logic         pcnt254,
    output logic [127:0]  ibfly_cfg0,              // stage1
    output logic [127:0]  ibfly_cfg1,
    output logic [127:0]  ibfly_cfg2,
    output logic [127:0]  ibfly_cfg3,
    output logic [127:0]  ibfly_cfg4,
    output logic [127:0]  ibfly_cfg5,
    output logic [127:0]  ibfly_cfg6,
    output logic [127:0]  ibfly_cfg7
);

// cfg7
// barrel rotator
logic [127:0] cfg7_temp0;
logic [127:0] cfg7_temp1;
logic [127:0] cfg7_temp2;
logic [127:0] cfg7_temp3;
logic [127:0] cfg7_temp4;
logic [127:0] cfg7_temp5;
logic [127:0] cfg7_temp6;
logic [127:0] cfg7_temp7;

always_comb begin
    case(pcnt127[0])
        1'b0  : cfg7_temp0 = 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
        1'b1  : cfg7_temp0 = 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_fffe;
    endcase
end
always_comb begin
    case(pcnt127[1])
        1'b0  : cfg7_temp1 = cfg7_temp0;
        1'b1  : cfg7_temp1 = {cfg7_temp0[125:0], ~cfg7_temp0[127:126]};
    endcase
end
always_comb begin
    case(pcnt127[2])
        1'b0  : cfg7_temp2 = cfg7_temp1;
        1'b1  : cfg7_temp2 = {cfg7_temp1[123:0], ~cfg7_temp1[127:124]};
    endcase
end
always_comb begin
    case(pcnt127[3])
        1'b0  : cfg7_temp3 = cfg7_temp2;
        1'b1  : cfg7_temp3 = {cfg7_temp2[119:0], ~cfg7_temp2[127:120]};
    endcase
end
always_comb begin
    case(pcnt127[4])
        1'b0  : cfg7_temp4 = cfg7_temp3;
        1'b1  : cfg7_temp4 = {cfg7_temp3[111:0], ~cfg7_temp3[127:112]};
    endcase
end
always_comb begin
    case(pcnt127[5])
        1'b0  : cfg7_temp5 = cfg7_temp4;
        1'b1  : cfg7_temp5 = {cfg7_temp4[95:0], ~cfg7_temp4[127:96]};
    endcase
end
always_comb begin
    case(pcnt127[6])
        1'b0  : cfg7_temp6 = cfg7_temp5;
        1'b1  : cfg7_temp6 = {cfg7_temp5[63:0], ~cfg7_temp5[127:64]};
    endcase
end
always_comb begin
    case(pcnt127[7])
        1'b0  : cfg7_temp7 = cfg7_temp6;
        1'b1  : cfg7_temp7 = ~cfg7_temp6;
    endcase
end
assign ibfly_cfg7 = cfg7_temp7;

// cfg6
logic [63:0] cfg6_temp00;
logic [63:0] cfg6_temp01;
logic [63:0] cfg6_temp02;
logic [63:0] cfg6_temp03;
logic [63:0] cfg6_temp04;
logic [63:0] cfg6_temp05;
logic [63:0] cfg6_temp06;
always_comb begin
    case(pcnt63[0])
        1'b0  : cfg6_temp00 = 64'hffff_ffff_ffff_ffff;
        1'b1  : cfg6_temp00 = 64'hffff_ffff_ffff_fffe;
    endcase
end
always_comb begin
    case(pcnt63[1])
        1'b0  : cfg6_temp01 = cfg6_temp00;
        1'b1  : cfg6_temp01 = {cfg6_temp00[61:0], ~cfg6_temp00[63:62]};
    endcase
end
always_comb begin
    case(pcnt63[2])
        1'b0  : cfg6_temp02 = cfg6_temp01;
        1'b1  : cfg6_temp02 = {cfg6_temp01[59:0], ~cfg6_temp01[63:60]};
    endcase
end
always_comb begin
    case(pcnt63[3])
        1'b0  : cfg6_temp03 = cfg6_temp02;
        1'b1  : cfg6_temp03 = {cfg6_temp02[55:0], ~cfg6_temp02[63:56]};
    endcase
end
always_comb begin
    case(pcnt63[4])
        1'b0  : cfg6_temp04 = cfg6_temp03;
        1'b1  : cfg6_temp04 = {cfg6_temp03[47:0], ~cfg6_temp03[63:48]};
    endcase
end
always_comb begin
    case(pcnt63[5])
        1'b0  : cfg6_temp05 = cfg6_temp04;
        1'b1  : cfg6_temp05 = {cfg6_temp04[31:0], ~cfg6_temp04[63:32]};
    endcase
end
always_comb begin
    case(pcnt63[6])
        1'b0  : cfg6_temp06 = cfg6_temp05;
        1'b1  : cfg6_temp06 = ~cfg6_temp05;
    endcase
end

logic [63:0] cfg6_temp10;
logic [63:0] cfg6_temp11;
logic [63:0] cfg6_temp12;
logic [63:0] cfg6_temp13;
logic [63:0] cfg6_temp14;
logic [63:0] cfg6_temp15;
logic [63:0] cfg6_temp16;
always_comb begin
    case(pcnt191[0])
        1'b0  : cfg6_temp10 = 64'hffff_ffff_ffff_ffff;
        1'b1  : cfg6_temp10 = 64'hffff_ffff_ffff_fffe;
    endcase
end
always_comb begin
    case(pcnt191[1])
        1'b0  : cfg6_temp11 = cfg6_temp10;
        1'b1  : cfg6_temp11 = {cfg6_temp10[61:0], ~cfg6_temp10[63:62]};
    endcase
end
always_comb begin
    case(pcnt191[2])
        1'b0  : cfg6_temp12 = cfg6_temp11;
        1'b1  : cfg6_temp12 = {cfg6_temp11[59:0], ~cfg6_temp11[63:60]};
    endcase
end
always_comb begin
    case(pcnt191[3])
        1'b0  : cfg6_temp13 = cfg6_temp12;
        1'b1  : cfg6_temp13 = {cfg6_temp12[55:0], ~cfg6_temp12[63:56]};
    endcase
end
always_comb begin
    case(pcnt191[4])
        1'b0  : cfg6_temp14 = cfg6_temp13;
        1'b1  : cfg6_temp14 = {cfg6_temp13[47:0], ~cfg6_temp13[63:48]};
    endcase
end
always_comb begin
    case(pcnt191[5])
        1'b0  : cfg6_temp15 = cfg6_temp14;
        1'b1  : cfg6_temp15 = {cfg6_temp14[31:0], ~cfg6_temp14[63:32]};
    endcase
end
always_comb begin
    case(pcnt191[6])
        1'b0  : cfg6_temp16 = cfg6_temp15;
        1'b1  : cfg6_temp16 = ~cfg6_temp15;
    endcase
end
assign ibfly_cfg6 = {cfg6_temp16, cfg6_temp06};

// cfg5
logic [31:0] cfg5_temp00;
logic [31:0] cfg5_temp01;
logic [31:0] cfg5_temp02;
logic [31:0] cfg5_temp03;
logic [31:0] cfg5_temp04;
logic [31:0] cfg5_temp05;
always_comb begin
    case(pcnt31[0])
        1'b0  : cfg5_temp00 = 32'hffff_ffff;
        1'b1  : cfg5_temp00 = 32'hffff_fffe;
    endcase
end
always_comb begin
    case(pcnt31[1])
        1'b0  : cfg5_temp01 = cfg5_temp00;
        1'b1  : cfg5_temp01 = {cfg5_temp00[29:0], ~cfg5_temp00[31:30]};
    endcase
end
always_comb begin
    case(pcnt31[2])
        1'b0  : cfg5_temp02 = cfg5_temp01;
        1'b1  : cfg5_temp02 = {cfg5_temp01[27:0], ~cfg5_temp01[31:28]};
    endcase
end
always_comb begin
    case(pcnt31[3])
        1'b0  : cfg5_temp03 = cfg5_temp02;
        1'b1  : cfg5_temp03 = {cfg5_temp02[23:0], ~cfg5_temp02[31:24]};
    endcase
end
always_comb begin
    case(pcnt31[4])
        1'b0  : cfg5_temp04 = cfg5_temp03;
        1'b1  : cfg5_temp04 = {cfg5_temp03[15:0], ~cfg5_temp03[31:16]};
    endcase
end
always_comb begin
    case(pcnt31[5])
        1'b0  : cfg5_temp05 = cfg5_temp04;
        1'b1  : cfg5_temp05 = ~cfg5_temp04;
    endcase
end

logic [31:0] cfg5_temp10;
logic [31:0] cfg5_temp11;
logic [31:0] cfg5_temp12;
logic [31:0] cfg5_temp13;
logic [31:0] cfg5_temp14;
logic [31:0] cfg5_temp15;
always_comb begin
    case(pcnt95[0])
        1'b0  : cfg5_temp10 = 32'hffff_ffff;
        1'b1  : cfg5_temp10 = 32'hffff_fffe;
    endcase
end
always_comb begin
    case(pcnt95[1])
        1'b0  : cfg5_temp11 = cfg5_temp10;
        1'b1  : cfg5_temp11 = {cfg5_temp10[29:0], ~cfg5_temp10[31:30]};
    endcase
end
always_comb begin
    case(pcnt95[2])
        1'b0  : cfg5_temp12 = cfg5_temp11;
        1'b1  : cfg5_temp12 = {cfg5_temp11[27:0], ~cfg5_temp11[31:28]};
    endcase
end
always_comb begin
    case(pcnt95[3])
        1'b0  : cfg5_temp13 = cfg5_temp12;
        1'b1  : cfg5_temp13 = {cfg5_temp12[23:0], ~cfg5_temp12[31:24]};
    endcase
end
always_comb begin
    case(pcnt95[4])
        1'b0  : cfg5_temp14 = cfg5_temp13;
        1'b1  : cfg5_temp14 = {cfg5_temp13[15:0], ~cfg5_temp13[31:16]};
    endcase
end
always_comb begin
    case(pcnt95[5])
        1'b0  : cfg5_temp15 = cfg5_temp14;
        1'b1  : cfg5_temp15 = ~cfg5_temp14;
    endcase
end

logic [31:0] cfg5_temp20;
logic [31:0] cfg5_temp21;
logic [31:0] cfg5_temp22;
logic [31:0] cfg5_temp23;
logic [31:0] cfg5_temp24;
logic [31:0] cfg5_temp25;
always_comb begin
    case(pcnt159[0])
        1'b0  : cfg5_temp20 = 32'hffff_ffff;
        1'b1  : cfg5_temp20 = 32'hffff_fffe;
    endcase
end
always_comb begin
    case(pcnt159[1])
        1'b0  : cfg5_temp21 = cfg5_temp20;
        1'b1  : cfg5_temp21 = {cfg5_temp20[29:0], ~cfg5_temp20[31:30]};
    endcase
end
always_comb begin
    case(pcnt159[2])
        1'b0  : cfg5_temp22 = cfg5_temp21;
        1'b1  : cfg5_temp22 = {cfg5_temp21[27:0], ~cfg5_temp21[31:28]};
    endcase
end
always_comb begin
    case(pcnt159[3])
        1'b0  : cfg5_temp23 = cfg5_temp22;
        1'b1  : cfg5_temp23 = {cfg5_temp22[23:0], ~cfg5_temp22[31:24]};
    endcase
end
always_comb begin
    case(pcnt159[4])
        1'b0  : cfg5_temp24 = cfg5_temp23;
        1'b1  : cfg5_temp24 = {cfg5_temp23[15:0], ~cfg5_temp23[31:16]};
    endcase
end
always_comb begin
    case(pcnt159[5])
        1'b0  : cfg5_temp25 = cfg5_temp24;
        1'b1  : cfg5_temp25 = ~cfg5_temp24;
    endcase
end

logic [31:0] cfg5_temp30;
logic [31:0] cfg5_temp31;
logic [31:0] cfg5_temp32;
logic [31:0] cfg5_temp33;
logic [31:0] cfg5_temp34;
logic [31:0] cfg5_temp35;
always_comb begin
    case(pcnt223[0])
        1'b0  : cfg5_temp30 = 32'hffff_ffff;
        1'b1  : cfg5_temp30 = 32'hffff_fffe;
    endcase
end
always_comb begin
    case(pcnt223[1])
        1'b0  : cfg5_temp31 = cfg5_temp30;
        1'b1  : cfg5_temp31 = {cfg5_temp30[29:0], ~cfg5_temp30[31:30]};
    endcase
end
always_comb begin
    case(pcnt223[2])
        1'b0  : cfg5_temp32 = cfg5_temp31;
        1'b1  : cfg5_temp32 = {cfg5_temp31[27:0], ~cfg5_temp31[31:28]};
    endcase
end
always_comb begin
    case(pcnt223[3])
        1'b0  : cfg5_temp33 = cfg5_temp32;
        1'b1  : cfg5_temp33 = {cfg5_temp32[23:0], ~cfg5_temp32[31:24]};
    endcase
end
always_comb begin
    case(pcnt223[4])
        1'b0  : cfg5_temp34 = cfg5_temp33;
        1'b1  : cfg5_temp34 = {cfg5_temp33[15:0], ~cfg5_temp33[31:16]};
    endcase
end
always_comb begin
    case(pcnt223[5])
        1'b0  : cfg5_temp35 = cfg5_temp34;
        1'b1  : cfg5_temp35 = ~cfg5_temp34;
    endcase
end
assign ibfly_cfg5 = {cfg5_temp35, cfg5_temp25, cfg5_temp15, cfg5_temp05};

// cfg 4
logic [15:0] cfg4_temp00;
logic [15:0] cfg4_temp01;
logic [15:0] cfg4_temp02;
logic [15:0] cfg4_temp03;
logic [15:0] cfg4_temp04;
always_comb begin
    case(pcnt15[0])
        1'b0  : cfg4_temp00 = 16'hffff;
        1'b1  : cfg4_temp00 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt15[1])
        1'b0  : cfg4_temp01 = cfg4_temp00;
        1'b1  : cfg4_temp01 =  {cfg4_temp00[13:0], ~cfg4_temp00[15:14]};
    endcase
end
always_comb begin
    case(pcnt15[2])
        1'b0  : cfg4_temp02 = cfg4_temp01;
        1'b1  : cfg4_temp02 =  {cfg4_temp01[11:0], ~cfg4_temp01[15:12]};
    endcase
end
always_comb begin
    case(pcnt15[3])
        1'b0  : cfg4_temp03 = cfg4_temp02;
        1'b1  : cfg4_temp03 =  {cfg4_temp02[7:0], ~cfg4_temp02[15:8]};
    endcase
end
always_comb begin
    case(pcnt15[4])
        1'b0  : cfg4_temp04 = cfg4_temp03;
        1'b1  : cfg4_temp04 = ~cfg4_temp03;
    endcase
end

logic [15:0] cfg4_temp10;
logic [15:0] cfg4_temp11;
logic [15:0] cfg4_temp12;
logic [15:0] cfg4_temp13;
logic [15:0] cfg4_temp14;
always_comb begin
    case(pcnt47[0])
        1'b0  : cfg4_temp10 = 16'hffff;
        1'b1  : cfg4_temp10 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt47[1])
        1'b0  : cfg4_temp11 = cfg4_temp10;
        1'b1  : cfg4_temp11 =  {cfg4_temp10[13:0], ~cfg4_temp10[15:14]};
    endcase
end
always_comb begin
    case(pcnt47[2])
        1'b0  : cfg4_temp12 = cfg4_temp11;
        1'b1  : cfg4_temp12 =  {cfg4_temp11[11:0], ~cfg4_temp11[15:12]};
    endcase
end
always_comb begin
    case(pcnt47[3])
        1'b0  : cfg4_temp13 = cfg4_temp12;
        1'b1  : cfg4_temp13 =  {cfg4_temp12[7:0], ~cfg4_temp12[15:8]};
    endcase
end
always_comb begin
    case(pcnt47[4])
        1'b0  : cfg4_temp14 = cfg4_temp13;
        1'b1  : cfg4_temp14 = ~cfg4_temp13;
    endcase
end

logic [15:0] cfg4_temp20;
logic [15:0] cfg4_temp21;
logic [15:0] cfg4_temp22;
logic [15:0] cfg4_temp23;
logic [15:0] cfg4_temp24;
always_comb begin
    case(pcnt79[0])
        1'b0  : cfg4_temp20 = 16'hffff;
        1'b1  : cfg4_temp20 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt79[1])
        1'b0  : cfg4_temp21 = cfg4_temp20;
        1'b1  : cfg4_temp21 =  {cfg4_temp20[13:0], ~cfg4_temp20[15:14]};
    endcase
end
always_comb begin
    case(pcnt79[2])
        1'b0  : cfg4_temp22 = cfg4_temp21;
        1'b1  : cfg4_temp22 =  {cfg4_temp21[11:0], ~cfg4_temp21[15:12]};
    endcase
end
always_comb begin
    case(pcnt79[3])
        1'b0  : cfg4_temp23 = cfg4_temp22;
        1'b1  : cfg4_temp23 =  {cfg4_temp22[7:0], ~cfg4_temp22[15:8]};
    endcase
end
always_comb begin
    case(pcnt79[4])
        1'b0  : cfg4_temp24 = cfg4_temp23;
        1'b1  : cfg4_temp24 = ~cfg4_temp23;
    endcase
end

logic [15:0] cfg4_temp30;
logic [15:0] cfg4_temp31;
logic [15:0] cfg4_temp32;
logic [15:0] cfg4_temp33;
logic [15:0] cfg4_temp34;
always_comb begin
    case(pcnt111[0])
        1'b0  : cfg4_temp30 = 16'hffff;
        1'b1  : cfg4_temp30 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt111[1])
        1'b0  : cfg4_temp31 = cfg4_temp30;
        1'b1  : cfg4_temp31 =  {cfg4_temp30[13:0], ~cfg4_temp30[15:14]};
    endcase
end
always_comb begin
    case(pcnt111[2])
        1'b0  : cfg4_temp32 = cfg4_temp31;
        1'b1  : cfg4_temp32 =  {cfg4_temp31[11:0], ~cfg4_temp31[15:12]};
    endcase
end
always_comb begin
    case(pcnt111[3])
        1'b0  : cfg4_temp33 = cfg4_temp32;
        1'b1  : cfg4_temp33 =  {cfg4_temp32[7:0], ~cfg4_temp32[15:8]};
    endcase
end
always_comb begin
    case(pcnt111[4])
        1'b0  : cfg4_temp34 = cfg4_temp33;
        1'b1  : cfg4_temp34 = ~cfg4_temp33;
    endcase
end

logic [15:0] cfg4_temp40;
logic [15:0] cfg4_temp41;
logic [15:0] cfg4_temp42;
logic [15:0] cfg4_temp43;
logic [15:0] cfg4_temp44;
always_comb begin
    case(pcnt143[0])
        1'b0  : cfg4_temp40 = 16'hffff;
        1'b1  : cfg4_temp40 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt143[1])
        1'b0  : cfg4_temp41 = cfg4_temp40;
        1'b1  : cfg4_temp41 =  {cfg4_temp40[13:0], ~cfg4_temp40[15:14]};
    endcase
end
always_comb begin
    case(pcnt143[2])
        1'b0  : cfg4_temp42 = cfg4_temp41;
        1'b1  : cfg4_temp42 =  {cfg4_temp41[11:0], ~cfg4_temp41[15:12]};
    endcase
end
always_comb begin
    case(pcnt143[3])
        1'b0  : cfg4_temp43 = cfg4_temp42;
        1'b1  : cfg4_temp43 =  {cfg4_temp42[7:0], ~cfg4_temp42[15:8]};
    endcase
end
always_comb begin
    case(pcnt143[4])
        1'b0  : cfg4_temp44 = cfg4_temp43;
        1'b1  : cfg4_temp44 = ~cfg4_temp43;
    endcase
end

logic [15:0] cfg4_temp50;
logic [15:0] cfg4_temp51;
logic [15:0] cfg4_temp52;
logic [15:0] cfg4_temp53;
logic [15:0] cfg4_temp54;
always_comb begin
    case(pcnt175[0])
        1'b0  : cfg4_temp50 = 16'hffff;
        1'b1  : cfg4_temp50 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt175[1])
        1'b0  : cfg4_temp51 = cfg4_temp50;
        1'b1  : cfg4_temp51 =  {cfg4_temp50[13:0], ~cfg4_temp50[15:14]};
    endcase
end
always_comb begin
    case(pcnt175[2])
        1'b0  : cfg4_temp52 = cfg4_temp51;
        1'b1  : cfg4_temp52 =  {cfg4_temp51[11:0], ~cfg4_temp51[15:12]};
    endcase
end
always_comb begin
    case(pcnt175[3])
        1'b0  : cfg4_temp53 = cfg4_temp52;
        1'b1  : cfg4_temp53 =  {cfg4_temp52[7:0], ~cfg4_temp52[15:8]};
    endcase
end
always_comb begin
    case(pcnt175[4])
        1'b0  : cfg4_temp54 = cfg4_temp53;
        1'b1  : cfg4_temp54 = ~cfg4_temp53;
    endcase
end

logic [15:0] cfg4_temp60;
logic [15:0] cfg4_temp61;
logic [15:0] cfg4_temp62;
logic [15:0] cfg4_temp63;
logic [15:0] cfg4_temp64;
always_comb begin
    case(pcnt207[0])
        1'b0  : cfg4_temp60 = 16'hffff;
        1'b1  : cfg4_temp60 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt207[1])
        1'b0  : cfg4_temp61 = cfg4_temp60;
        1'b1  : cfg4_temp61 =  {cfg4_temp60[13:0], ~cfg4_temp60[15:14]};
    endcase
end
always_comb begin
    case(pcnt207[2])
        1'b0  : cfg4_temp62 = cfg4_temp61;
        1'b1  : cfg4_temp62 =  {cfg4_temp61[11:0], ~cfg4_temp61[15:12]};
    endcase
end
always_comb begin
    case(pcnt207[3])
        1'b0  : cfg4_temp63 = cfg4_temp62;
        1'b1  : cfg4_temp63 =  {cfg4_temp62[7:0], ~cfg4_temp62[15:8]};
    endcase
end
always_comb begin
    case(pcnt207[4])
        1'b0  : cfg4_temp64 = cfg4_temp63;
        1'b1  : cfg4_temp64 = ~cfg4_temp63;
    endcase
end

logic [15:0] cfg4_temp70;
logic [15:0] cfg4_temp71;
logic [15:0] cfg4_temp72;
logic [15:0] cfg4_temp73;
logic [15:0] cfg4_temp74;
always_comb begin
    case(pcnt239[0])
        1'b0  : cfg4_temp70 = 16'hffff;
        1'b1  : cfg4_temp70 = 16'hfffe;
    endcase
end
always_comb begin
    case(pcnt239[1])
        1'b0  : cfg4_temp71 = cfg4_temp70;
        1'b1  : cfg4_temp71 =  {cfg4_temp70[13:0], ~cfg4_temp70[15:14]};
    endcase
end
always_comb begin
    case(pcnt239[2])
        1'b0  : cfg4_temp72 = cfg4_temp71;
        1'b1  : cfg4_temp72 =  {cfg4_temp71[11:0], ~cfg4_temp71[15:12]};
    endcase
end
always_comb begin
    case(pcnt239[3])
        1'b0  : cfg4_temp73 = cfg4_temp72;
        1'b1  : cfg4_temp73 =  {cfg4_temp72[7:0], ~cfg4_temp72[15:8]};
    endcase
end
always_comb begin
    case(pcnt239[4])
        1'b0  : cfg4_temp74 = cfg4_temp73;
        1'b1  : cfg4_temp74 = ~cfg4_temp73;
    endcase
end
assign ibfly_cfg4 = {cfg4_temp74, cfg4_temp64, cfg4_temp54, cfg4_temp44,
                     cfg4_temp34, cfg4_temp24, cfg4_temp14, cfg4_temp04};

// cfg 3
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
        1'b1  : cfg3_temp01 =  {cfg3_temp00[5:0], ~cfg3_temp00[7:6]};
    endcase
end
always_comb begin
    case(pcnt7[2])
        1'b0  : cfg3_temp02 = cfg3_temp01;
        1'b1  : cfg3_temp02 =  {cfg3_temp01[3:0], ~cfg3_temp01[7:4]};
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
        1'b1  : cfg3_temp11 =  {cfg3_temp10[5:0], ~cfg3_temp10[7:6]};
    endcase
end
always_comb begin
    case(pcnt23[2])
        1'b0  : cfg3_temp12 = cfg3_temp11;
        1'b1  : cfg3_temp12 =  {cfg3_temp11[3:0], ~cfg3_temp11[7:4]};
    endcase
end
always_comb begin
    case(pcnt23[3])
        1'b0  : cfg3_temp13 = cfg3_temp12;
        1'b1  : cfg3_temp13 = ~cfg3_temp12;
    endcase
end

logic [7:0] cfg3_temp20;
logic [7:0] cfg3_temp21;
logic [7:0] cfg3_temp22;
logic [7:0] cfg3_temp23;
always_comb begin
    case(pcnt39[0])
        1'b0  : cfg3_temp20 = 8'hff;
        1'b1  : cfg3_temp20 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt39[1])
        1'b0  : cfg3_temp21 = cfg3_temp20;
        1'b1  : cfg3_temp21 =  {cfg3_temp20[5:0], ~cfg3_temp20[7:6]};
    endcase
end
always_comb begin
    case(pcnt39[2])
        1'b0  : cfg3_temp22 = cfg3_temp21;
        1'b1  : cfg3_temp22 =  {cfg3_temp21[3:0], ~cfg3_temp21[7:4]};
    endcase
end
always_comb begin
    case(pcnt39[3])
        1'b0  : cfg3_temp23 = cfg3_temp22;
        1'b1  : cfg3_temp23 = ~cfg3_temp22;
    endcase
end

logic [7:0] cfg3_temp30;
logic [7:0] cfg3_temp31;
logic [7:0] cfg3_temp32;
logic [7:0] cfg3_temp33;
always_comb begin
    case(pcnt55[0])
        1'b0  : cfg3_temp30 = 8'hff;
        1'b1  : cfg3_temp30 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt55[1])
        1'b0  : cfg3_temp31 = cfg3_temp30;
        1'b1  : cfg3_temp31 =  {cfg3_temp30[5:0], ~cfg3_temp30[7:6]};
    endcase
end
always_comb begin
    case(pcnt55[2])
        1'b0  : cfg3_temp32 = cfg3_temp31;
        1'b1  : cfg3_temp32 =  {cfg3_temp31[3:0], ~cfg3_temp31[7:4]};
    endcase
end
always_comb begin
    case(pcnt55[3])
        1'b0  : cfg3_temp33 = cfg3_temp32;
        1'b1  : cfg3_temp33 = ~cfg3_temp32;
    endcase
end

logic [7:0] cfg3_temp40;
logic [7:0] cfg3_temp41;
logic [7:0] cfg3_temp42;
logic [7:0] cfg3_temp43;
always_comb begin
    case(pcnt71[0])
        1'b0  : cfg3_temp40 = 8'hff;
        1'b1  : cfg3_temp40 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt71[1])
        1'b0  : cfg3_temp41 = cfg3_temp40;
        1'b1  : cfg3_temp41 =  {cfg3_temp40[5:0], ~cfg3_temp40[7:6]};
    endcase
end
always_comb begin
    case(pcnt71[2])
        1'b0  : cfg3_temp42 = cfg3_temp41;
        1'b1  : cfg3_temp42 =  {cfg3_temp41[3:0], ~cfg3_temp41[7:4]};
    endcase
end
always_comb begin
    case(pcnt71[3])
        1'b0  : cfg3_temp43 = cfg3_temp42;
        1'b1  : cfg3_temp43 = ~cfg3_temp42;
    endcase
end

logic [7:0] cfg3_temp50;
logic [7:0] cfg3_temp51;
logic [7:0] cfg3_temp52;
logic [7:0] cfg3_temp53;
always_comb begin
    case(pcnt87[0])
        1'b0  : cfg3_temp50 = 8'hff;
        1'b1  : cfg3_temp50 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt87[1])
        1'b0  : cfg3_temp51 = cfg3_temp50;
        1'b1  : cfg3_temp51 =  {cfg3_temp50[5:0], ~cfg3_temp50[7:6]};
    endcase
end
always_comb begin
    case(pcnt87[2])
        1'b0  : cfg3_temp52 = cfg3_temp51;
        1'b1  : cfg3_temp52 =  {cfg3_temp51[3:0], ~cfg3_temp51[7:4]};
    endcase
end
always_comb begin
    case(pcnt87[3])
        1'b0  : cfg3_temp53 = cfg3_temp52;
        1'b1  : cfg3_temp53 = ~cfg3_temp52;
    endcase
end

logic [7:0] cfg3_temp60;
logic [7:0] cfg3_temp61;
logic [7:0] cfg3_temp62;
logic [7:0] cfg3_temp63;
always_comb begin
    case(pcnt103[0])
        1'b0  : cfg3_temp60 = 8'hff;
        1'b1  : cfg3_temp60 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt103[1])
        1'b0  : cfg3_temp61 = cfg3_temp60;
        1'b1  : cfg3_temp61 =  {cfg3_temp60[5:0], ~cfg3_temp60[7:6]};
    endcase
end
always_comb begin
    case(pcnt103[2])
        1'b0  : cfg3_temp62 = cfg3_temp61;
        1'b1  : cfg3_temp62 =  {cfg3_temp61[3:0], ~cfg3_temp61[7:4]};
    endcase
end
always_comb begin
    case(pcnt103[3])
        1'b0  : cfg3_temp63 = cfg3_temp62;
        1'b1  : cfg3_temp63 = ~cfg3_temp62;
    endcase
end

logic [7:0] cfg3_temp70;
logic [7:0] cfg3_temp71;
logic [7:0] cfg3_temp72;
logic [7:0] cfg3_temp73;
always_comb begin
    case(pcnt119[0])
        1'b0  : cfg3_temp70 = 8'hff;
        1'b1  : cfg3_temp70 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt119[1])
        1'b0  : cfg3_temp71 = cfg3_temp70;
        1'b1  : cfg3_temp71 =  {cfg3_temp70[5:0], ~cfg3_temp70[7:6]};
    endcase
end
always_comb begin
    case(pcnt119[2])
        1'b0  : cfg3_temp72 = cfg3_temp71;
        1'b1  : cfg3_temp72 =  {cfg3_temp71[3:0], ~cfg3_temp71[7:4]};
    endcase
end
always_comb begin
    case(pcnt119[3])
        1'b0  : cfg3_temp73 = cfg3_temp72;
        1'b1  : cfg3_temp73 = ~cfg3_temp72;
    endcase
end

logic [7:0] cfg3_temp80;
logic [7:0] cfg3_temp81;
logic [7:0] cfg3_temp82;
logic [7:0] cfg3_temp83;
always_comb begin
    case(pcnt135[0])
        1'b0  : cfg3_temp80 = 8'hff;
        1'b1  : cfg3_temp80 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt135[1])
        1'b0  : cfg3_temp81 = cfg3_temp80;
        1'b1  : cfg3_temp81 =  {cfg3_temp80[5:0], ~cfg3_temp80[7:6]};
    endcase
end
always_comb begin
    case(pcnt135[2])
        1'b0  : cfg3_temp82 = cfg3_temp81;
        1'b1  : cfg3_temp82 =  {cfg3_temp81[3:0], ~cfg3_temp81[7:4]};
    endcase
end
always_comb begin
    case(pcnt135[3])
        1'b0  : cfg3_temp83 = cfg3_temp82;
        1'b1  : cfg3_temp83 = ~cfg3_temp82;
    endcase
end

logic [7:0] cfg3_temp90;
logic [7:0] cfg3_temp91;
logic [7:0] cfg3_temp92;
logic [7:0] cfg3_temp93;
always_comb begin
    case(pcnt151[0])
        1'b0  : cfg3_temp90 = 8'hff;
        1'b1  : cfg3_temp90 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt151[1])
        1'b0  : cfg3_temp91 = cfg3_temp90;
        1'b1  : cfg3_temp91 =  {cfg3_temp90[5:0], ~cfg3_temp90[7:6]};
    endcase
end
always_comb begin
    case(pcnt151[2])
        1'b0  : cfg3_temp92 = cfg3_temp91;
        1'b1  : cfg3_temp92 =  {cfg3_temp91[3:0], ~cfg3_temp91[7:4]};
    endcase
end
always_comb begin
    case(pcnt151[3])
        1'b0  : cfg3_temp93 = cfg3_temp92;
        1'b1  : cfg3_temp93 = ~cfg3_temp92;
    endcase
end

logic [7:0] cfg3_temp100;
logic [7:0] cfg3_temp101;
logic [7:0] cfg3_temp102;
logic [7:0] cfg3_temp103;
always_comb begin
    case(pcnt167[0])
        1'b0  : cfg3_temp100 = 8'hff;
        1'b1  : cfg3_temp100 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt167[1])
        1'b0  : cfg3_temp101 = cfg3_temp100;
        1'b1  : cfg3_temp101 =  {cfg3_temp100[5:0], ~cfg3_temp100[7:6]};
    endcase
end
always_comb begin
    case(pcnt167[2])
        1'b0  : cfg3_temp102 = cfg3_temp101;
        1'b1  : cfg3_temp102 =  {cfg3_temp101[3:0], ~cfg3_temp101[7:4]};
    endcase
end
always_comb begin
    case(pcnt167[3])
        1'b0  : cfg3_temp103 = cfg3_temp102;
        1'b1  : cfg3_temp103 = ~cfg3_temp102;
    endcase
end

logic [7:0] cfg3_temp110;
logic [7:0] cfg3_temp111;
logic [7:0] cfg3_temp112;
logic [7:0] cfg3_temp113;
always_comb begin
    case(pcnt183[0])
        1'b0  : cfg3_temp110 = 8'hff;
        1'b1  : cfg3_temp110 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt183[1])
        1'b0  : cfg3_temp111 = cfg3_temp110;
        1'b1  : cfg3_temp111 =  {cfg3_temp110[5:0], ~cfg3_temp110[7:6]};
    endcase
end
always_comb begin
    case(pcnt183[2])
        1'b0  : cfg3_temp112 = cfg3_temp111;
        1'b1  : cfg3_temp112 =  {cfg3_temp111[3:0], ~cfg3_temp111[7:4]};
    endcase
end
always_comb begin
    case(pcnt183[3])
        1'b0  : cfg3_temp113 = cfg3_temp112;
        1'b1  : cfg3_temp113 = ~cfg3_temp112;
    endcase
end

logic [7:0] cfg3_temp120;
logic [7:0] cfg3_temp121;
logic [7:0] cfg3_temp122;
logic [7:0] cfg3_temp123;
always_comb begin
    case(pcnt199[0])
        1'b0  : cfg3_temp120 = 8'hff;
        1'b1  : cfg3_temp120 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt199[1])
        1'b0  : cfg3_temp121 = cfg3_temp120;
        1'b1  : cfg3_temp121 =  {cfg3_temp120[5:0], ~cfg3_temp120[7:6]};
    endcase
end
always_comb begin
    case(pcnt199[2])
        1'b0  : cfg3_temp122 = cfg3_temp121;
        1'b1  : cfg3_temp122 =  {cfg3_temp121[3:0], ~cfg3_temp121[7:4]};
    endcase
end
always_comb begin
    case(pcnt199[3])
        1'b0  : cfg3_temp123 = cfg3_temp122;
        1'b1  : cfg3_temp123 = ~cfg3_temp122;
    endcase
end

logic [7:0] cfg3_temp130;
logic [7:0] cfg3_temp131;
logic [7:0] cfg3_temp132;
logic [7:0] cfg3_temp133;
always_comb begin
    case(pcnt215[0])
        1'b0  : cfg3_temp130 = 8'hff;
        1'b1  : cfg3_temp130 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt215[1])
        1'b0  : cfg3_temp131 = cfg3_temp130;
        1'b1  : cfg3_temp131 =  {cfg3_temp130[5:0], ~cfg3_temp130[7:6]};
    endcase
end
always_comb begin
    case(pcnt215[2])
        1'b0  : cfg3_temp132 = cfg3_temp131;
        1'b1  : cfg3_temp132 =  {cfg3_temp131[3:0], ~cfg3_temp131[7:4]};
    endcase
end
always_comb begin
    case(pcnt215[3])
        1'b0  : cfg3_temp133 = cfg3_temp132;
        1'b1  : cfg3_temp133 = ~cfg3_temp132;
    endcase
end

logic [7:0] cfg3_temp140;
logic [7:0] cfg3_temp141;
logic [7:0] cfg3_temp142;
logic [7:0] cfg3_temp143;
always_comb begin
    case(pcnt231[0])
        1'b0  : cfg3_temp140 = 8'hff;
        1'b1  : cfg3_temp140 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt231[1])
        1'b0  : cfg3_temp141 = cfg3_temp140;
        1'b1  : cfg3_temp141 =  {cfg3_temp140[5:0], ~cfg3_temp140[7:6]};
    endcase
end
always_comb begin
    case(pcnt231[2])
        1'b0  : cfg3_temp142 = cfg3_temp141;
        1'b1  : cfg3_temp142 =  {cfg3_temp141[3:0], ~cfg3_temp141[7:4]};
    endcase
end
always_comb begin
    case(pcnt231[3])
        1'b0  : cfg3_temp143 = cfg3_temp142;
        1'b1  : cfg3_temp143 = ~cfg3_temp142;
    endcase
end

logic [7:0] cfg3_temp150;
logic [7:0] cfg3_temp151;
logic [7:0] cfg3_temp152;
logic [7:0] cfg3_temp153;
always_comb begin
    case(pcnt247[0])
        1'b0  : cfg3_temp150 = 8'hff;
        1'b1  : cfg3_temp150 = 8'hfe;
    endcase
end
always_comb begin
    case(pcnt247[1])
        1'b0  : cfg3_temp151 = cfg3_temp150;
        1'b1  : cfg3_temp151 =  {cfg3_temp150[5:0], ~cfg3_temp150[7:6]};
    endcase
end
always_comb begin
    case(pcnt247[2])
        1'b0  : cfg3_temp152 = cfg3_temp151;
        1'b1  : cfg3_temp152 =  {cfg3_temp151[3:0], ~cfg3_temp151[7:4]};
    endcase
end
always_comb begin
    case(pcnt247[3])
        1'b0  : cfg3_temp153 = cfg3_temp152;
        1'b1  : cfg3_temp153 = ~cfg3_temp152;
    endcase
end

assign ibfly_cfg3 = {cfg3_temp153, cfg3_temp143, cfg3_temp133, cfg3_temp123,
                     cfg3_temp113, cfg3_temp103, cfg3_temp93, cfg3_temp83,
                     cfg3_temp73, cfg3_temp63, cfg3_temp53, cfg3_temp43,
                     cfg3_temp33, cfg3_temp23, cfg3_temp13, cfg3_temp03};

// this RTL code eat shit!
// cfg 2
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
        1'b1  : cfg2_temp01 =  {cfg2_temp00[1:0], ~cfg2_temp00[3:2]};
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
        1'b1  : cfg2_temp11 =  {cfg2_temp10[1:0], ~cfg2_temp10[3:2]};
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
        1'b1  : cfg2_temp21 =  {cfg2_temp20[1:0], ~cfg2_temp20[3:2]};
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
        1'b1  : cfg2_temp31 =  {cfg2_temp30[1:0], ~cfg2_temp30[3:2]};
    endcase
end
always_comb begin
    case(pcnt27[2])
        1'b0  : cfg2_temp32 = cfg2_temp31;
        1'b1  : cfg2_temp32 = ~cfg2_temp31;
    endcase
end

logic [3:0] cfg2_temp40;
logic [3:0] cfg2_temp41;
logic [3:0] cfg2_temp42;
always_comb begin
    case(pcnt35[0])
        1'b0  : cfg2_temp40 = 4'hf;
        1'b1  : cfg2_temp40 = 4'he;
    endcase
end
always_comb begin
    case(pcnt35[1])
        1'b0  : cfg2_temp41 = cfg2_temp40;
        1'b1  : cfg2_temp41 =  {cfg2_temp40[1:0], ~cfg2_temp40[3:2]};
    endcase
end
always_comb begin
    case(pcnt35[2])
        1'b0  : cfg2_temp42 = cfg2_temp41;
        1'b1  : cfg2_temp42 = ~cfg2_temp41;
    endcase
end

logic [3:0] cfg2_temp50;
logic [3:0] cfg2_temp51;
logic [3:0] cfg2_temp52;
always_comb begin
    case(pcnt43[0])
        1'b0  : cfg2_temp50 = 4'hf;
        1'b1  : cfg2_temp50 = 4'he;
    endcase
end
always_comb begin
    case(pcnt43[1])
        1'b0  : cfg2_temp51 = cfg2_temp50;
        1'b1  : cfg2_temp51 =  {cfg2_temp50[1:0], ~cfg2_temp50[3:2]};
    endcase
end
always_comb begin
    case(pcnt43[2])
        1'b0  : cfg2_temp52 = cfg2_temp51;
        1'b1  : cfg2_temp52 = ~cfg2_temp51;
    endcase
end

logic [3:0] cfg2_temp60;
logic [3:0] cfg2_temp61;
logic [3:0] cfg2_temp62;
always_comb begin
    case(pcnt51[0])
        1'b0  : cfg2_temp60 = 4'hf;
        1'b1  : cfg2_temp60 = 4'he;
    endcase
end
always_comb begin
    case(pcnt51[1])
        1'b0  : cfg2_temp61 = cfg2_temp60;
        1'b1  : cfg2_temp61 =  {cfg2_temp60[1:0], ~cfg2_temp60[3:2]};
    endcase
end
always_comb begin
    case(pcnt51[2])
        1'b0  : cfg2_temp62 = cfg2_temp61;
        1'b1  : cfg2_temp62 = ~cfg2_temp61;
    endcase
end

logic [3:0] cfg2_temp70;
logic [3:0] cfg2_temp71;
logic [3:0] cfg2_temp72;
always_comb begin
    case(pcnt59[0])
        1'b0  : cfg2_temp70 = 4'hf;
        1'b1  : cfg2_temp70 = 4'he;
    endcase
end
always_comb begin
    case(pcnt59[1])
        1'b0  : cfg2_temp71 = cfg2_temp70;
        1'b1  : cfg2_temp71 =  {cfg2_temp70[1:0], ~cfg2_temp70[3:2]};
    endcase
end
always_comb begin
    case(pcnt59[2])
        1'b0  : cfg2_temp72 = cfg2_temp71;
        1'b1  : cfg2_temp72 = ~cfg2_temp71;
    endcase
end

logic [3:0] cfg2_temp80;
logic [3:0] cfg2_temp81;
logic [3:0] cfg2_temp82;
always_comb begin
    case(pcnt67[0])
        1'b0  : cfg2_temp80 = 4'hf;
        1'b1  : cfg2_temp80 = 4'he;
    endcase
end
always_comb begin
    case(pcnt67[1])
        1'b0  : cfg2_temp81 = cfg2_temp80;
        1'b1  : cfg2_temp81 =  {cfg2_temp80[1:0], ~cfg2_temp80[3:2]};
    endcase
end
always_comb begin
    case(pcnt67[2])
        1'b0  : cfg2_temp82 = cfg2_temp81;
        1'b1  : cfg2_temp82 = ~cfg2_temp81;
    endcase
end

logic [3:0] cfg2_temp90;
logic [3:0] cfg2_temp91;
logic [3:0] cfg2_temp92;
always_comb begin
    case(pcnt75[0])
        1'b0  : cfg2_temp90 = 4'hf;
        1'b1  : cfg2_temp90 = 4'he;
    endcase
end
always_comb begin
    case(pcnt75[1])
        1'b0  : cfg2_temp91 = cfg2_temp90;
        1'b1  : cfg2_temp91 =  {cfg2_temp90[1:0], ~cfg2_temp90[3:2]};
    endcase
end
always_comb begin
    case(pcnt75[2])
        1'b0  : cfg2_temp92 = cfg2_temp91;
        1'b1  : cfg2_temp92 = ~cfg2_temp91;
    endcase
end

logic [3:0] cfg2_temp100;
logic [3:0] cfg2_temp101;
logic [3:0] cfg2_temp102;
always_comb begin
    case(pcnt83[0])
        1'b0  : cfg2_temp100 = 4'hf;
        1'b1  : cfg2_temp100 = 4'he;
    endcase
end
always_comb begin
    case(pcnt83[1])
        1'b0  : cfg2_temp101 = cfg2_temp100;
        1'b1  : cfg2_temp101 =  {cfg2_temp100[1:0], ~cfg2_temp100[3:2]};
    endcase
end
always_comb begin
    case(pcnt83[2])
        1'b0  : cfg2_temp102 = cfg2_temp101;
        1'b1  : cfg2_temp102 = ~cfg2_temp101;
    endcase
end

logic [3:0] cfg2_temp110;
logic [3:0] cfg2_temp111;
logic [3:0] cfg2_temp112;
always_comb begin
    case(pcnt91[0])
        1'b0  : cfg2_temp110 = 4'hf;
        1'b1  : cfg2_temp110 = 4'he;
    endcase
end
always_comb begin
    case(pcnt91[1])
        1'b0  : cfg2_temp111 = cfg2_temp110;
        1'b1  : cfg2_temp111 =  {cfg2_temp110[1:0], ~cfg2_temp110[3:2]};
    endcase
end
always_comb begin
    case(pcnt91[2])
        1'b0  : cfg2_temp112 = cfg2_temp111;
        1'b1  : cfg2_temp112 = ~cfg2_temp111;
    endcase
end

logic [3:0] cfg2_temp120;
logic [3:0] cfg2_temp121;
logic [3:0] cfg2_temp122;
always_comb begin
    case(pcnt99[0])
        1'b0  : cfg2_temp120 = 4'hf;
        1'b1  : cfg2_temp120 = 4'he;
    endcase
end
always_comb begin
    case(pcnt99[1])
        1'b0  : cfg2_temp121 = cfg2_temp120;
        1'b1  : cfg2_temp121 =  {cfg2_temp120[1:0], ~cfg2_temp120[3:2]};
    endcase
end
always_comb begin
    case(pcnt99[2])
        1'b0  : cfg2_temp122 = cfg2_temp121;
        1'b1  : cfg2_temp122 = ~cfg2_temp121;
    endcase
end

logic [3:0] cfg2_temp130;
logic [3:0] cfg2_temp131;
logic [3:0] cfg2_temp132;
always_comb begin
    case(pcnt107[0])
        1'b0  : cfg2_temp130 = 4'hf;
        1'b1  : cfg2_temp130 = 4'he;
    endcase
end
always_comb begin
    case(pcnt107[1])
        1'b0  : cfg2_temp131 = cfg2_temp130;
        1'b1  : cfg2_temp131 =  {cfg2_temp130[1:0], ~cfg2_temp130[3:2]};
    endcase
end
always_comb begin
    case(pcnt107[2])
        1'b0  : cfg2_temp132 = cfg2_temp131;
        1'b1  : cfg2_temp132 = ~cfg2_temp131;
    endcase
end

logic [3:0] cfg2_temp140;
logic [3:0] cfg2_temp141;
logic [3:0] cfg2_temp142;
always_comb begin
    case(pcnt115[0])
        1'b0  : cfg2_temp140 = 4'hf;
        1'b1  : cfg2_temp140 = 4'he;
    endcase
end
always_comb begin
    case(pcnt115[1])
        1'b0  : cfg2_temp141 = cfg2_temp140;
        1'b1  : cfg2_temp141 =  {cfg2_temp140[1:0], ~cfg2_temp140[3:2]};
    endcase
end
always_comb begin
    case(pcnt115[2])
        1'b0  : cfg2_temp142 = cfg2_temp141;
        1'b1  : cfg2_temp142 = ~cfg2_temp141;
    endcase
end

logic [3:0] cfg2_temp150;
logic [3:0] cfg2_temp151;
logic [3:0] cfg2_temp152;
always_comb begin
    case(pcnt123[0])
        1'b0  : cfg2_temp150 = 4'hf;
        1'b1  : cfg2_temp150 = 4'he;
    endcase
end
always_comb begin
    case(pcnt123[1])
        1'b0  : cfg2_temp151 = cfg2_temp150;
        1'b1  : cfg2_temp151 =  {cfg2_temp150[1:0], ~cfg2_temp150[3:2]};
    endcase
end
always_comb begin
    case(pcnt123[2])
        1'b0  : cfg2_temp152 = cfg2_temp151;
        1'b1  : cfg2_temp152 = ~cfg2_temp151;
    endcase
end

logic [3:0] cfg2_temp160;
logic [3:0] cfg2_temp161;
logic [3:0] cfg2_temp162;
always_comb begin
    case(pcnt131[0])
        1'b0  : cfg2_temp160 = 4'hf;
        1'b1  : cfg2_temp160 = 4'he;
    endcase
end
always_comb begin
    case(pcnt131[1])
        1'b0  : cfg2_temp161 = cfg2_temp160;
        1'b1  : cfg2_temp161 =  {cfg2_temp160[1:0], ~cfg2_temp160[3:2]};
    endcase
end
always_comb begin
    case(pcnt131[2])
        1'b0  : cfg2_temp162 = cfg2_temp161;
        1'b1  : cfg2_temp162 = ~cfg2_temp161;
    endcase
end

logic [3:0] cfg2_temp170;
logic [3:0] cfg2_temp171;
logic [3:0] cfg2_temp172;
always_comb begin
    case(pcnt139[0])
        1'b0  : cfg2_temp170 = 4'hf;
        1'b1  : cfg2_temp170 = 4'he;
    endcase
end
always_comb begin
    case(pcnt139[1])
        1'b0  : cfg2_temp171 = cfg2_temp170;
        1'b1  : cfg2_temp171 =  {cfg2_temp170[1:0], ~cfg2_temp170[3:2]};
    endcase
end
always_comb begin
    case(pcnt139[2])
        1'b0  : cfg2_temp172 = cfg2_temp171;
        1'b1  : cfg2_temp172 = ~cfg2_temp171;
    endcase
end

logic [3:0] cfg2_temp180;
logic [3:0] cfg2_temp181;
logic [3:0] cfg2_temp182;
always_comb begin
    case(pcnt147[0])
        1'b0  : cfg2_temp180 = 4'hf;
        1'b1  : cfg2_temp180 = 4'he;
    endcase
end
always_comb begin
    case(pcnt147[1])
        1'b0  : cfg2_temp181 = cfg2_temp180;
        1'b1  : cfg2_temp181 =  {cfg2_temp180[1:0], ~cfg2_temp180[3:2]};
    endcase
end
always_comb begin
    case(pcnt147[2])
        1'b0  : cfg2_temp182 = cfg2_temp181;
        1'b1  : cfg2_temp182 = ~cfg2_temp181;
    endcase
end

logic [3:0] cfg2_temp190;
logic [3:0] cfg2_temp191;
logic [3:0] cfg2_temp192;
always_comb begin
    case(pcnt155[0])
        1'b0  : cfg2_temp190 = 4'hf;
        1'b1  : cfg2_temp190 = 4'he;
    endcase
end
always_comb begin
    case(pcnt155[1])
        1'b0  : cfg2_temp191 = cfg2_temp190;
        1'b1  : cfg2_temp191 =  {cfg2_temp190[1:0], ~cfg2_temp190[3:2]};
    endcase
end
always_comb begin
    case(pcnt155[2])
        1'b0  : cfg2_temp192 = cfg2_temp191;
        1'b1  : cfg2_temp192 = ~cfg2_temp191;
    endcase
end

logic [3:0] cfg2_temp200;
logic [3:0] cfg2_temp201;
logic [3:0] cfg2_temp202;
always_comb begin
    case(pcnt163[0])
        1'b0  : cfg2_temp200 = 4'hf;
        1'b1  : cfg2_temp200 = 4'he;
    endcase
end
always_comb begin
    case(pcnt163[1])
        1'b0  : cfg2_temp201 = cfg2_temp200;
        1'b1  : cfg2_temp201 =  {cfg2_temp200[1:0], ~cfg2_temp200[3:2]};
    endcase
end
always_comb begin
    case(pcnt163[2])
        1'b0  : cfg2_temp202 = cfg2_temp201;
        1'b1  : cfg2_temp202 = ~cfg2_temp201;
    endcase
end

logic [3:0] cfg2_temp210;
logic [3:0] cfg2_temp211;
logic [3:0] cfg2_temp212;
always_comb begin
    case(pcnt171[0])
        1'b0  : cfg2_temp210 = 4'hf;
        1'b1  : cfg2_temp210 = 4'he;
    endcase
end
always_comb begin
    case(pcnt171[1])
        1'b0  : cfg2_temp211 = cfg2_temp210;
        1'b1  : cfg2_temp211 =  {cfg2_temp210[1:0], ~cfg2_temp210[3:2]};
    endcase
end
always_comb begin
    case(pcnt171[2])
        1'b0  : cfg2_temp212 = cfg2_temp211;
        1'b1  : cfg2_temp212 = ~cfg2_temp211;
    endcase
end

logic [3:0] cfg2_temp220;
logic [3:0] cfg2_temp221;
logic [3:0] cfg2_temp222;
always_comb begin
    case(pcnt179[0])
        1'b0  : cfg2_temp220 = 4'hf;
        1'b1  : cfg2_temp220 = 4'he;
    endcase
end
always_comb begin
    case(pcnt179[1])
        1'b0  : cfg2_temp221 = cfg2_temp220;
        1'b1  : cfg2_temp221 =  {cfg2_temp220[1:0], ~cfg2_temp220[3:2]};
    endcase
end
always_comb begin
    case(pcnt179[2])
        1'b0  : cfg2_temp222 = cfg2_temp221;
        1'b1  : cfg2_temp222 = ~cfg2_temp221;
    endcase
end

logic [3:0] cfg2_temp230;
logic [3:0] cfg2_temp231;
logic [3:0] cfg2_temp232;
always_comb begin
    case(pcnt187[0])
        1'b0  : cfg2_temp230 = 4'hf;
        1'b1  : cfg2_temp230 = 4'he;
    endcase
end
always_comb begin
    case(pcnt187[1])
        1'b0  : cfg2_temp231 = cfg2_temp230;
        1'b1  : cfg2_temp231 =  {cfg2_temp230[1:0], ~cfg2_temp230[3:2]};
    endcase
end
always_comb begin
    case(pcnt187[2])
        1'b0  : cfg2_temp232 = cfg2_temp231;
        1'b1  : cfg2_temp232 = ~cfg2_temp231;
    endcase
end

logic [3:0] cfg2_temp240;
logic [3:0] cfg2_temp241;
logic [3:0] cfg2_temp242;
always_comb begin
    case(pcnt195[0])
        1'b0  : cfg2_temp240 = 4'hf;
        1'b1  : cfg2_temp240 = 4'he;
    endcase
end
always_comb begin
    case(pcnt195[1])
        1'b0  : cfg2_temp241 = cfg2_temp240;
        1'b1  : cfg2_temp241 =  {cfg2_temp240[1:0], ~cfg2_temp240[3:2]};
    endcase
end
always_comb begin
    case(pcnt195[2])
        1'b0  : cfg2_temp242 = cfg2_temp241;
        1'b1  : cfg2_temp242 = ~cfg2_temp241;
    endcase
end

logic [3:0] cfg2_temp250;
logic [3:0] cfg2_temp251;
logic [3:0] cfg2_temp252;
always_comb begin
    case(pcnt203[0])
        1'b0  : cfg2_temp250 = 4'hf;
        1'b1  : cfg2_temp250 = 4'he;
    endcase
end
always_comb begin
    case(pcnt203[1])
        1'b0  : cfg2_temp251 = cfg2_temp250;
        1'b1  : cfg2_temp251 =  {cfg2_temp250[1:0], ~cfg2_temp250[3:2]};
    endcase
end
always_comb begin
    case(pcnt203[2])
        1'b0  : cfg2_temp252 = cfg2_temp251;
        1'b1  : cfg2_temp252 = ~cfg2_temp251;
    endcase
end

logic [3:0] cfg2_temp260;
logic [3:0] cfg2_temp261;
logic [3:0] cfg2_temp262;
always_comb begin
    case(pcnt211[0])
        1'b0  : cfg2_temp260 = 4'hf;
        1'b1  : cfg2_temp260 = 4'he;
    endcase
end
always_comb begin
    case(pcnt211[1])
        1'b0  : cfg2_temp261 = cfg2_temp260;
        1'b1  : cfg2_temp261 =  {cfg2_temp260[1:0], ~cfg2_temp260[3:2]};
    endcase
end
always_comb begin
    case(pcnt211[2])
        1'b0  : cfg2_temp262 = cfg2_temp261;
        1'b1  : cfg2_temp262 = ~cfg2_temp261;
    endcase
end

logic [3:0] cfg2_temp270;
logic [3:0] cfg2_temp271;
logic [3:0] cfg2_temp272;
always_comb begin
    case(pcnt219[0])
        1'b0  : cfg2_temp270 = 4'hf;
        1'b1  : cfg2_temp270 = 4'he;
    endcase
end
always_comb begin
    case(pcnt219[1])
        1'b0  : cfg2_temp271 = cfg2_temp270;
        1'b1  : cfg2_temp271 =  {cfg2_temp270[1:0], ~cfg2_temp270[3:2]};
    endcase
end
always_comb begin
    case(pcnt219[2])
        1'b0  : cfg2_temp272 = cfg2_temp271;
        1'b1  : cfg2_temp272 = ~cfg2_temp271;
    endcase
end

logic [3:0] cfg2_temp280;
logic [3:0] cfg2_temp281;
logic [3:0] cfg2_temp282;
always_comb begin
    case(pcnt227[0])
        1'b0  : cfg2_temp280 = 4'hf;
        1'b1  : cfg2_temp280 = 4'he;
    endcase
end
always_comb begin
    case(pcnt227[1])
        1'b0  : cfg2_temp281 = cfg2_temp280;
        1'b1  : cfg2_temp281 =  {cfg2_temp280[1:0], ~cfg2_temp280[3:2]};
    endcase
end
always_comb begin
    case(pcnt227[2])
        1'b0  : cfg2_temp282 = cfg2_temp281;
        1'b1  : cfg2_temp282 = ~cfg2_temp281;
    endcase
end

logic [3:0] cfg2_temp290;
logic [3:0] cfg2_temp291;
logic [3:0] cfg2_temp292;
always_comb begin
    case(pcnt235[0])
        1'b0  : cfg2_temp290 = 4'hf;
        1'b1  : cfg2_temp290 = 4'he;
    endcase
end
always_comb begin
    case(pcnt235[1])
        1'b0  : cfg2_temp291 = cfg2_temp290;
        1'b1  : cfg2_temp291 =  {cfg2_temp290[1:0], ~cfg2_temp290[3:2]};
    endcase
end
always_comb begin
    case(pcnt235[2])
        1'b0  : cfg2_temp292 = cfg2_temp291;
        1'b1  : cfg2_temp292 = ~cfg2_temp291;
    endcase
end

logic [3:0] cfg2_temp300;
logic [3:0] cfg2_temp301;
logic [3:0] cfg2_temp302;
always_comb begin
    case(pcnt243[0])
        1'b0  : cfg2_temp300 = 4'hf;
        1'b1  : cfg2_temp300 = 4'he;
    endcase
end
always_comb begin
    case(pcnt243[1])
        1'b0  : cfg2_temp301 = cfg2_temp300;
        1'b1  : cfg2_temp301 =  {cfg2_temp300[1:0], ~cfg2_temp300[3:2]};
    endcase
end
always_comb begin
    case(pcnt243[2])
        1'b0  : cfg2_temp302 = cfg2_temp301;
        1'b1  : cfg2_temp302 = ~cfg2_temp301;
    endcase
end

logic [3:0] cfg2_temp310;
logic [3:0] cfg2_temp311;
logic [3:0] cfg2_temp312;
always_comb begin
    case(pcnt251[0])
        1'b0  : cfg2_temp310 = 4'hf;
        1'b1  : cfg2_temp310 = 4'he;
    endcase
end
always_comb begin
    case(pcnt251[1])
        1'b0  : cfg2_temp311 = cfg2_temp310;
        1'b1  : cfg2_temp311 =  {cfg2_temp310[1:0], ~cfg2_temp310[3:2]};
    endcase
end
always_comb begin
    case(pcnt251[2])
        1'b0  : cfg2_temp312 = cfg2_temp311;
        1'b1  : cfg2_temp312 = ~cfg2_temp311;
    endcase
end

assign ibfly_cfg2 = {cfg2_temp312, cfg2_temp302, cfg2_temp292, cfg2_temp282,
                     cfg2_temp272, cfg2_temp262, cfg2_temp252, cfg2_temp242,
                     cfg2_temp232, cfg2_temp222, cfg2_temp212, cfg2_temp202,
                     cfg2_temp192, cfg2_temp182, cfg2_temp172, cfg2_temp162,
                     cfg2_temp152, cfg2_temp142, cfg2_temp132, cfg2_temp122,
                     cfg2_temp112, cfg2_temp102, cfg2_temp92, cfg2_temp82,
                     cfg2_temp72, cfg2_temp62, cfg2_temp52, cfg2_temp42,
                     cfg2_temp32, cfg2_temp22, cfg2_temp12, cfg2_temp02};

// fuck it..
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

logic [1:0] cfg1_temp80;
logic [1:0] cfg1_temp81;
always_comb begin
    case(pcnt33[0])
        1'b0  : cfg1_temp80 = 2'b11;
        1'b1  : cfg1_temp80 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt33[1])
        1'b0  : cfg1_temp81 = cfg1_temp80;
        1'b1  : cfg1_temp81 = ~cfg1_temp80;
    endcase
end

logic [1:0] cfg1_temp90;
logic [1:0] cfg1_temp91;
always_comb begin
    case(pcnt37[0])
        1'b0  : cfg1_temp90 = 2'b11;
        1'b1  : cfg1_temp90 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt37[1])
        1'b0  : cfg1_temp91 = cfg1_temp90;
        1'b1  : cfg1_temp91 = ~cfg1_temp90;
    endcase
end

logic [1:0] cfg1_temp100;
logic [1:0] cfg1_temp101;
always_comb begin
    case(pcnt41[0])
        1'b0  : cfg1_temp100 = 2'b11;
        1'b1  : cfg1_temp100 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt41[1])
        1'b0  : cfg1_temp101 = cfg1_temp100;
        1'b1  : cfg1_temp101 = ~cfg1_temp100;
    endcase
end

logic [1:0] cfg1_temp110;
logic [1:0] cfg1_temp111;
always_comb begin
    case(pcnt45[0])
        1'b0  : cfg1_temp110 = 2'b11;
        1'b1  : cfg1_temp110 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt45[1])
        1'b0  : cfg1_temp111 = cfg1_temp110;
        1'b1  : cfg1_temp111 = ~cfg1_temp110;
    endcase
end

logic [1:0] cfg1_temp120;
logic [1:0] cfg1_temp121;
always_comb begin
    case(pcnt49[0])
        1'b0  : cfg1_temp120 = 2'b11;
        1'b1  : cfg1_temp120 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt49[1])
        1'b0  : cfg1_temp121 = cfg1_temp120;
        1'b1  : cfg1_temp121 = ~cfg1_temp120;
    endcase
end

logic [1:0] cfg1_temp130;
logic [1:0] cfg1_temp131;
always_comb begin
    case(pcnt53[0])
        1'b0  : cfg1_temp130 = 2'b11;
        1'b1  : cfg1_temp130 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt53[1])
        1'b0  : cfg1_temp131 = cfg1_temp130;
        1'b1  : cfg1_temp131 = ~cfg1_temp130;
    endcase
end

logic [1:0] cfg1_temp140;
logic [1:0] cfg1_temp141;
always_comb begin
    case(pcnt57[0])
        1'b0  : cfg1_temp140 = 2'b11;
        1'b1  : cfg1_temp140 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt57[1])
        1'b0  : cfg1_temp141 = cfg1_temp140;
        1'b1  : cfg1_temp141 = ~cfg1_temp140;
    endcase
end

logic [1:0] cfg1_temp150;
logic [1:0] cfg1_temp151;
always_comb begin
    case(pcnt61[0])
        1'b0  : cfg1_temp150 = 2'b11;
        1'b1  : cfg1_temp150 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt61[1])
        1'b0  : cfg1_temp151 = cfg1_temp150;
        1'b1  : cfg1_temp151 = ~cfg1_temp150;
    endcase
end

logic [1:0] cfg1_temp160;
logic [1:0] cfg1_temp161;
always_comb begin
    case(pcnt65[0])
        1'b0  : cfg1_temp160 = 2'b11;
        1'b1  : cfg1_temp160 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt65[1])
        1'b0  : cfg1_temp161 = cfg1_temp160;
        1'b1  : cfg1_temp161 = ~cfg1_temp160;
    endcase
end

logic [1:0] cfg1_temp170;
logic [1:0] cfg1_temp171;
always_comb begin
    case(pcnt69[0])
        1'b0  : cfg1_temp170 = 2'b11;
        1'b1  : cfg1_temp170 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt69[1])
        1'b0  : cfg1_temp171 = cfg1_temp170;
        1'b1  : cfg1_temp171 = ~cfg1_temp170;
    endcase
end

logic [1:0] cfg1_temp180;
logic [1:0] cfg1_temp181;
always_comb begin
    case(pcnt73[0])
        1'b0  : cfg1_temp180 = 2'b11;
        1'b1  : cfg1_temp180 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt73[1])
        1'b0  : cfg1_temp181 = cfg1_temp180;
        1'b1  : cfg1_temp181 = ~cfg1_temp180;
    endcase
end

logic [1:0] cfg1_temp190;
logic [1:0] cfg1_temp191;
always_comb begin
    case(pcnt77[0])
        1'b0  : cfg1_temp190 = 2'b11;
        1'b1  : cfg1_temp190 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt77[1])
        1'b0  : cfg1_temp191 = cfg1_temp190;
        1'b1  : cfg1_temp191 = ~cfg1_temp190;
    endcase
end

logic [1:0] cfg1_temp200;
logic [1:0] cfg1_temp201;
always_comb begin
    case(pcnt81[0])
        1'b0  : cfg1_temp200 = 2'b11;
        1'b1  : cfg1_temp200 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt81[1])
        1'b0  : cfg1_temp201 = cfg1_temp200;
        1'b1  : cfg1_temp201 = ~cfg1_temp200;
    endcase
end

logic [1:0] cfg1_temp210;
logic [1:0] cfg1_temp211;
always_comb begin
    case(pcnt85[0])
        1'b0  : cfg1_temp210 = 2'b11;
        1'b1  : cfg1_temp210 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt85[1])
        1'b0  : cfg1_temp211 = cfg1_temp210;
        1'b1  : cfg1_temp211 = ~cfg1_temp210;
    endcase
end

logic [1:0] cfg1_temp220;
logic [1:0] cfg1_temp221;
always_comb begin
    case(pcnt89[0])
        1'b0  : cfg1_temp220 = 2'b11;
        1'b1  : cfg1_temp220 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt89[1])
        1'b0  : cfg1_temp221 = cfg1_temp220;
        1'b1  : cfg1_temp221 = ~cfg1_temp220;
    endcase
end

logic [1:0] cfg1_temp230;
logic [1:0] cfg1_temp231;
always_comb begin
    case(pcnt93[0])
        1'b0  : cfg1_temp230 = 2'b11;
        1'b1  : cfg1_temp230 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt93[1])
        1'b0  : cfg1_temp231 = cfg1_temp230;
        1'b1  : cfg1_temp231 = ~cfg1_temp230;
    endcase
end

logic [1:0] cfg1_temp240;
logic [1:0] cfg1_temp241;
always_comb begin
    case(pcnt97[0])
        1'b0  : cfg1_temp240 = 2'b11;
        1'b1  : cfg1_temp240 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt97[1])
        1'b0  : cfg1_temp241 = cfg1_temp240;
        1'b1  : cfg1_temp241 = ~cfg1_temp240;
    endcase
end

logic [1:0] cfg1_temp250;
logic [1:0] cfg1_temp251;
always_comb begin
    case(pcnt101[0])
        1'b0  : cfg1_temp250 = 2'b11;
        1'b1  : cfg1_temp250 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt101[1])
        1'b0  : cfg1_temp251 = cfg1_temp250;
        1'b1  : cfg1_temp251 = ~cfg1_temp250;
    endcase
end

logic [1:0] cfg1_temp260;
logic [1:0] cfg1_temp261;
always_comb begin
    case(pcnt105[0])
        1'b0  : cfg1_temp260 = 2'b11;
        1'b1  : cfg1_temp260 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt105[1])
        1'b0  : cfg1_temp261 = cfg1_temp260;
        1'b1  : cfg1_temp261 = ~cfg1_temp260;
    endcase
end

logic [1:0] cfg1_temp270;
logic [1:0] cfg1_temp271;
always_comb begin
    case(pcnt109[0])
        1'b0  : cfg1_temp270 = 2'b11;
        1'b1  : cfg1_temp270 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt109[1])
        1'b0  : cfg1_temp271 = cfg1_temp270;
        1'b1  : cfg1_temp271 = ~cfg1_temp270;
    endcase
end

logic [1:0] cfg1_temp280;
logic [1:0] cfg1_temp281;
always_comb begin
    case(pcnt113[0])
        1'b0  : cfg1_temp280 = 2'b11;
        1'b1  : cfg1_temp280 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt113[1])
        1'b0  : cfg1_temp281 = cfg1_temp280;
        1'b1  : cfg1_temp281 = ~cfg1_temp280;
    endcase
end

logic [1:0] cfg1_temp290;
logic [1:0] cfg1_temp291;
always_comb begin
    case(pcnt117[0])
        1'b0  : cfg1_temp290 = 2'b11;
        1'b1  : cfg1_temp290 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt117[1])
        1'b0  : cfg1_temp291 = cfg1_temp290;
        1'b1  : cfg1_temp291 = ~cfg1_temp290;
    endcase
end

logic [1:0] cfg1_temp300;
logic [1:0] cfg1_temp301;
always_comb begin
    case(pcnt121[0])
        1'b0  : cfg1_temp300 = 2'b11;
        1'b1  : cfg1_temp300 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt121[1])
        1'b0  : cfg1_temp301 = cfg1_temp300;
        1'b1  : cfg1_temp301 = ~cfg1_temp300;
    endcase
end

logic [1:0] cfg1_temp310;
logic [1:0] cfg1_temp311;
always_comb begin
    case(pcnt125[0])
        1'b0  : cfg1_temp310 = 2'b11;
        1'b1  : cfg1_temp310 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt125[1])
        1'b0  : cfg1_temp311 = cfg1_temp310;
        1'b1  : cfg1_temp311 = ~cfg1_temp310;
    endcase
end

logic [1:0] cfg1_temp320;
logic [1:0] cfg1_temp321;
always_comb begin
    case(pcnt129[0])
        1'b0  : cfg1_temp320 = 2'b11;
        1'b1  : cfg1_temp320 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt129[1])
        1'b0  : cfg1_temp321 = cfg1_temp320;
        1'b1  : cfg1_temp321 = ~cfg1_temp320;
    endcase
end

logic [1:0] cfg1_temp330;
logic [1:0] cfg1_temp331;
always_comb begin
    case(pcnt133[0])
        1'b0  : cfg1_temp330 = 2'b11;
        1'b1  : cfg1_temp330 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt133[1])
        1'b0  : cfg1_temp331 = cfg1_temp330;
        1'b1  : cfg1_temp331 = ~cfg1_temp330;
    endcase
end

logic [1:0] cfg1_temp340;
logic [1:0] cfg1_temp341;
always_comb begin
    case(pcnt137[0])
        1'b0  : cfg1_temp340 = 2'b11;
        1'b1  : cfg1_temp340 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt137[1])
        1'b0  : cfg1_temp341 = cfg1_temp340;
        1'b1  : cfg1_temp341 = ~cfg1_temp340;
    endcase
end

logic [1:0] cfg1_temp350;
logic [1:0] cfg1_temp351;
always_comb begin
    case(pcnt141[0])
        1'b0  : cfg1_temp350 = 2'b11;
        1'b1  : cfg1_temp350 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt141[1])
        1'b0  : cfg1_temp351 = cfg1_temp350;
        1'b1  : cfg1_temp351 = ~cfg1_temp350;
    endcase
end

logic [1:0] cfg1_temp360;
logic [1:0] cfg1_temp361;
always_comb begin
    case(pcnt145[0])
        1'b0  : cfg1_temp360 = 2'b11;
        1'b1  : cfg1_temp360 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt145[1])
        1'b0  : cfg1_temp361 = cfg1_temp360;
        1'b1  : cfg1_temp361 = ~cfg1_temp360;
    endcase
end

logic [1:0] cfg1_temp370;
logic [1:0] cfg1_temp371;
always_comb begin
    case(pcnt149[0])
        1'b0  : cfg1_temp370 = 2'b11;
        1'b1  : cfg1_temp370 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt149[1])
        1'b0  : cfg1_temp371 = cfg1_temp370;
        1'b1  : cfg1_temp371 = ~cfg1_temp370;
    endcase
end

logic [1:0] cfg1_temp380;
logic [1:0] cfg1_temp381;
always_comb begin
    case(pcnt153[0])
        1'b0  : cfg1_temp380 = 2'b11;
        1'b1  : cfg1_temp380 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt153[1])
        1'b0  : cfg1_temp381 = cfg1_temp380;
        1'b1  : cfg1_temp381 = ~cfg1_temp380;
    endcase
end

logic [1:0] cfg1_temp390;
logic [1:0] cfg1_temp391;
always_comb begin
    case(pcnt157[0])
        1'b0  : cfg1_temp390 = 2'b11;
        1'b1  : cfg1_temp390 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt157[1])
        1'b0  : cfg1_temp391 = cfg1_temp390;
        1'b1  : cfg1_temp391 = ~cfg1_temp390;
    endcase
end

logic [1:0] cfg1_temp400;
logic [1:0] cfg1_temp401;
always_comb begin
    case(pcnt161[0])
        1'b0  : cfg1_temp400 = 2'b11;
        1'b1  : cfg1_temp400 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt161[1])
        1'b0  : cfg1_temp401 = cfg1_temp400;
        1'b1  : cfg1_temp401 = ~cfg1_temp400;
    endcase
end

logic [1:0] cfg1_temp410;
logic [1:0] cfg1_temp411;
always_comb begin
    case(pcnt165[0])
        1'b0  : cfg1_temp410 = 2'b11;
        1'b1  : cfg1_temp410 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt165[1])
        1'b0  : cfg1_temp411 = cfg1_temp410;
        1'b1  : cfg1_temp411 = ~cfg1_temp410;
    endcase
end

logic [1:0] cfg1_temp420;
logic [1:0] cfg1_temp421;
always_comb begin
    case(pcnt169[0])
        1'b0  : cfg1_temp420 = 2'b11;
        1'b1  : cfg1_temp420 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt169[1])
        1'b0  : cfg1_temp421 = cfg1_temp420;
        1'b1  : cfg1_temp421 = ~cfg1_temp420;
    endcase
end

logic [1:0] cfg1_temp430;
logic [1:0] cfg1_temp431;
always_comb begin
    case(pcnt173[0])
        1'b0  : cfg1_temp430 = 2'b11;
        1'b1  : cfg1_temp430 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt173[1])
        1'b0  : cfg1_temp431 = cfg1_temp430;
        1'b1  : cfg1_temp431 = ~cfg1_temp430;
    endcase
end

logic [1:0] cfg1_temp440;
logic [1:0] cfg1_temp441;
always_comb begin
    case(pcnt177[0])
        1'b0  : cfg1_temp440 = 2'b11;
        1'b1  : cfg1_temp440 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt177[1])
        1'b0  : cfg1_temp441 = cfg1_temp440;
        1'b1  : cfg1_temp441 = ~cfg1_temp440;
    endcase
end

logic [1:0] cfg1_temp450;
logic [1:0] cfg1_temp451;
always_comb begin
    case(pcnt181[0])
        1'b0  : cfg1_temp450 = 2'b11;
        1'b1  : cfg1_temp450 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt181[1])
        1'b0  : cfg1_temp451 = cfg1_temp450;
        1'b1  : cfg1_temp451 = ~cfg1_temp450;
    endcase
end

logic [1:0] cfg1_temp460;
logic [1:0] cfg1_temp461;
always_comb begin
    case(pcnt185[0])
        1'b0  : cfg1_temp460 = 2'b11;
        1'b1  : cfg1_temp460 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt185[1])
        1'b0  : cfg1_temp461 = cfg1_temp460;
        1'b1  : cfg1_temp461 = ~cfg1_temp460;
    endcase
end

logic [1:0] cfg1_temp470;
logic [1:0] cfg1_temp471;
always_comb begin
    case(pcnt189[0])
        1'b0  : cfg1_temp470 = 2'b11;
        1'b1  : cfg1_temp470 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt189[1])
        1'b0  : cfg1_temp471 = cfg1_temp470;
        1'b1  : cfg1_temp471 = ~cfg1_temp470;
    endcase
end

logic [1:0] cfg1_temp480;
logic [1:0] cfg1_temp481;
always_comb begin
    case(pcnt193[0])
        1'b0  : cfg1_temp480 = 2'b11;
        1'b1  : cfg1_temp480 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt193[1])
        1'b0  : cfg1_temp481 = cfg1_temp480;
        1'b1  : cfg1_temp481 = ~cfg1_temp480;
    endcase
end

logic [1:0] cfg1_temp490;
logic [1:0] cfg1_temp491;
always_comb begin
    case(pcnt197[0])
        1'b0  : cfg1_temp490 = 2'b11;
        1'b1  : cfg1_temp490 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt197[1])
        1'b0  : cfg1_temp491 = cfg1_temp490;
        1'b1  : cfg1_temp491 = ~cfg1_temp490;
    endcase
end

logic [1:0] cfg1_temp500;
logic [1:0] cfg1_temp501;
always_comb begin
    case(pcnt201[0])
        1'b0  : cfg1_temp500 = 2'b11;
        1'b1  : cfg1_temp500 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt201[1])
        1'b0  : cfg1_temp501 = cfg1_temp500;
        1'b1  : cfg1_temp501 = ~cfg1_temp500;
    endcase
end

logic [1:0] cfg1_temp510;
logic [1:0] cfg1_temp511;
always_comb begin
    case(pcnt205[0])
        1'b0  : cfg1_temp510 = 2'b11;
        1'b1  : cfg1_temp510 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt205[1])
        1'b0  : cfg1_temp511 = cfg1_temp510;
        1'b1  : cfg1_temp511 = ~cfg1_temp510;
    endcase
end

logic [1:0] cfg1_temp520;
logic [1:0] cfg1_temp521;
always_comb begin
    case(pcnt209[0])
        1'b0  : cfg1_temp520 = 2'b11;
        1'b1  : cfg1_temp520 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt209[1])
        1'b0  : cfg1_temp521 = cfg1_temp520;
        1'b1  : cfg1_temp521 = ~cfg1_temp520;
    endcase
end

logic [1:0] cfg1_temp530;
logic [1:0] cfg1_temp531;
always_comb begin
    case(pcnt213[0])
        1'b0  : cfg1_temp530 = 2'b11;
        1'b1  : cfg1_temp530 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt213[1])
        1'b0  : cfg1_temp531 = cfg1_temp530;
        1'b1  : cfg1_temp531 = ~cfg1_temp530;
    endcase
end

logic [1:0] cfg1_temp540;
logic [1:0] cfg1_temp541;
always_comb begin
    case(pcnt217[0])
        1'b0  : cfg1_temp540 = 2'b11;
        1'b1  : cfg1_temp540 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt217[1])
        1'b0  : cfg1_temp541 = cfg1_temp540;
        1'b1  : cfg1_temp541 = ~cfg1_temp540;
    endcase
end

logic [1:0] cfg1_temp550;
logic [1:0] cfg1_temp551;
always_comb begin
    case(pcnt221[0])
        1'b0  : cfg1_temp550 = 2'b11;
        1'b1  : cfg1_temp550 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt221[1])
        1'b0  : cfg1_temp551 = cfg1_temp550;
        1'b1  : cfg1_temp551 = ~cfg1_temp550;
    endcase
end

logic [1:0] cfg1_temp560;
logic [1:0] cfg1_temp561;
always_comb begin
    case(pcnt225[0])
        1'b0  : cfg1_temp560 = 2'b11;
        1'b1  : cfg1_temp560 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt225[1])
        1'b0  : cfg1_temp561 = cfg1_temp560;
        1'b1  : cfg1_temp561 = ~cfg1_temp560;
    endcase
end

logic [1:0] cfg1_temp570;
logic [1:0] cfg1_temp571;
always_comb begin
    case(pcnt229[0])
        1'b0  : cfg1_temp570 = 2'b11;
        1'b1  : cfg1_temp570 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt229[1])
        1'b0  : cfg1_temp571 = cfg1_temp570;
        1'b1  : cfg1_temp571 = ~cfg1_temp570;
    endcase
end

logic [1:0] cfg1_temp580;
logic [1:0] cfg1_temp581;
always_comb begin
    case(pcnt233[0])
        1'b0  : cfg1_temp580 = 2'b11;
        1'b1  : cfg1_temp580 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt233[1])
        1'b0  : cfg1_temp581 = cfg1_temp580;
        1'b1  : cfg1_temp581 = ~cfg1_temp580;
    endcase
end

logic [1:0] cfg1_temp590;
logic [1:0] cfg1_temp591;
always_comb begin
    case(pcnt237[0])
        1'b0  : cfg1_temp590 = 2'b11;
        1'b1  : cfg1_temp590 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt237[1])
        1'b0  : cfg1_temp591 = cfg1_temp590;
        1'b1  : cfg1_temp591 = ~cfg1_temp590;
    endcase
end

logic [1:0] cfg1_temp600;
logic [1:0] cfg1_temp601;
always_comb begin
    case(pcnt241[0])
        1'b0  : cfg1_temp600 = 2'b11;
        1'b1  : cfg1_temp600 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt241[1])
        1'b0  : cfg1_temp601 = cfg1_temp600;
        1'b1  : cfg1_temp601 = ~cfg1_temp600;
    endcase
end

logic [1:0] cfg1_temp610;
logic [1:0] cfg1_temp611;
always_comb begin
    case(pcnt245[0])
        1'b0  : cfg1_temp610 = 2'b11;
        1'b1  : cfg1_temp610 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt245[1])
        1'b0  : cfg1_temp611 = cfg1_temp610;
        1'b1  : cfg1_temp611 = ~cfg1_temp610;
    endcase
end

logic [1:0] cfg1_temp620;
logic [1:0] cfg1_temp621;
always_comb begin
    case(pcnt249[0])
        1'b0  : cfg1_temp620 = 2'b11;
        1'b1  : cfg1_temp620 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt249[1])
        1'b0  : cfg1_temp621 = cfg1_temp620;
        1'b1  : cfg1_temp621 = ~cfg1_temp620;
    endcase
end

logic [1:0] cfg1_temp630;
logic [1:0] cfg1_temp631;
always_comb begin
    case(pcnt253[0])
        1'b0  : cfg1_temp630 = 2'b11;
        1'b1  : cfg1_temp630 = 2'b10;
    endcase
end
always_comb begin
    case(pcnt253[1])
        1'b0  : cfg1_temp631 = cfg1_temp630;
        1'b1  : cfg1_temp631 = ~cfg1_temp630;
    endcase
end

assign ibfly_cfg1 = {cfg1_temp631, cfg1_temp621, cfg1_temp611, cfg1_temp601,
                     cfg1_temp591, cfg1_temp581, cfg1_temp571, cfg1_temp561,
                     cfg1_temp551, cfg1_temp541, cfg1_temp531, cfg1_temp521,
                     cfg1_temp511, cfg1_temp501, cfg1_temp491, cfg1_temp481,
                     cfg1_temp471, cfg1_temp461, cfg1_temp451, cfg1_temp441,
                     cfg1_temp431, cfg1_temp421, cfg1_temp411, cfg1_temp401,
                     cfg1_temp391, cfg1_temp381, cfg1_temp371, cfg1_temp361,
                     cfg1_temp351, cfg1_temp341, cfg1_temp331, cfg1_temp321,
                     cfg1_temp311, cfg1_temp301, cfg1_temp291, cfg1_temp281,
                     cfg1_temp271, cfg1_temp261, cfg1_temp251, cfg1_temp241,
                     cfg1_temp231, cfg1_temp221, cfg1_temp211, cfg1_temp201,
                     cfg1_temp191, cfg1_temp181, cfg1_temp171, cfg1_temp161,
                     cfg1_temp151, cfg1_temp141, cfg1_temp131, cfg1_temp121,
                     cfg1_temp111, cfg1_temp101, cfg1_temp91, cfg1_temp81,
                     cfg1_temp71, cfg1_temp61, cfg1_temp51, cfg1_temp41,
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
assign ibfly_cfg0[16] = ~pcnt32;
assign ibfly_cfg0[17] = ~pcnt34;
assign ibfly_cfg0[18] = ~pcnt36;
assign ibfly_cfg0[19] = ~pcnt38;
assign ibfly_cfg0[20] = ~pcnt40;
assign ibfly_cfg0[21] = ~pcnt42;
assign ibfly_cfg0[22] = ~pcnt44;
assign ibfly_cfg0[23] = ~pcnt46;
assign ibfly_cfg0[24] = ~pcnt48;
assign ibfly_cfg0[25] = ~pcnt50;
assign ibfly_cfg0[26] = ~pcnt52;
assign ibfly_cfg0[27] = ~pcnt54;
assign ibfly_cfg0[28] = ~pcnt56;
assign ibfly_cfg0[29] = ~pcnt58;
assign ibfly_cfg0[30] = ~pcnt60;
assign ibfly_cfg0[31] = ~pcnt62;
assign ibfly_cfg0[32] = ~pcnt64;
assign ibfly_cfg0[33] = ~pcnt66;
assign ibfly_cfg0[34] = ~pcnt68;
assign ibfly_cfg0[35] = ~pcnt70;
assign ibfly_cfg0[36] = ~pcnt72;
assign ibfly_cfg0[37] = ~pcnt74;
assign ibfly_cfg0[38] = ~pcnt76;
assign ibfly_cfg0[39] = ~pcnt78;
assign ibfly_cfg0[40] = ~pcnt80;
assign ibfly_cfg0[41] = ~pcnt82;
assign ibfly_cfg0[42] = ~pcnt84;
assign ibfly_cfg0[43] = ~pcnt86;
assign ibfly_cfg0[44] = ~pcnt88;
assign ibfly_cfg0[45] = ~pcnt90;
assign ibfly_cfg0[46] = ~pcnt92;
assign ibfly_cfg0[47] = ~pcnt94;
assign ibfly_cfg0[48] = ~pcnt96;
assign ibfly_cfg0[49] = ~pcnt98;
assign ibfly_cfg0[50] = ~pcnt100;
assign ibfly_cfg0[51] = ~pcnt102;
assign ibfly_cfg0[52] = ~pcnt104;
assign ibfly_cfg0[53] = ~pcnt106;
assign ibfly_cfg0[54] = ~pcnt108;
assign ibfly_cfg0[55] = ~pcnt110;
assign ibfly_cfg0[56] = ~pcnt112;
assign ibfly_cfg0[57] = ~pcnt114;
assign ibfly_cfg0[58] = ~pcnt116;
assign ibfly_cfg0[59] = ~pcnt118;
assign ibfly_cfg0[60] = ~pcnt120;
assign ibfly_cfg0[61] = ~pcnt122;
assign ibfly_cfg0[62] = ~pcnt124;
assign ibfly_cfg0[63] = ~pcnt126;
assign ibfly_cfg0[64] = ~pcnt128;
assign ibfly_cfg0[65] = ~pcnt130;
assign ibfly_cfg0[66] = ~pcnt132;
assign ibfly_cfg0[67] = ~pcnt134;
assign ibfly_cfg0[68] = ~pcnt136;
assign ibfly_cfg0[69] = ~pcnt138;
assign ibfly_cfg0[70] = ~pcnt140;
assign ibfly_cfg0[71] = ~pcnt142;
assign ibfly_cfg0[72] = ~pcnt144;
assign ibfly_cfg0[73] = ~pcnt146;
assign ibfly_cfg0[74] = ~pcnt148;
assign ibfly_cfg0[75] = ~pcnt150;
assign ibfly_cfg0[76] = ~pcnt152;
assign ibfly_cfg0[77] = ~pcnt154;
assign ibfly_cfg0[78] = ~pcnt156;
assign ibfly_cfg0[79] = ~pcnt158;
assign ibfly_cfg0[80] = ~pcnt160;
assign ibfly_cfg0[81] = ~pcnt162;
assign ibfly_cfg0[82] = ~pcnt164;
assign ibfly_cfg0[83] = ~pcnt166;
assign ibfly_cfg0[84] = ~pcnt168;
assign ibfly_cfg0[85] = ~pcnt170;
assign ibfly_cfg0[86] = ~pcnt172;
assign ibfly_cfg0[87] = ~pcnt174;
assign ibfly_cfg0[88] = ~pcnt176;
assign ibfly_cfg0[89] = ~pcnt178;
assign ibfly_cfg0[90] = ~pcnt180;
assign ibfly_cfg0[91] = ~pcnt182;
assign ibfly_cfg0[92] = ~pcnt184;
assign ibfly_cfg0[93] = ~pcnt186;
assign ibfly_cfg0[94] = ~pcnt188;
assign ibfly_cfg0[95] = ~pcnt190;
assign ibfly_cfg0[96] = ~pcnt192;
assign ibfly_cfg0[97] = ~pcnt194;
assign ibfly_cfg0[98] = ~pcnt196;
assign ibfly_cfg0[99] = ~pcnt198;
assign ibfly_cfg0[100] = ~pcnt200;
assign ibfly_cfg0[101] = ~pcnt202;
assign ibfly_cfg0[102] = ~pcnt204;
assign ibfly_cfg0[103] = ~pcnt206;
assign ibfly_cfg0[104] = ~pcnt208;
assign ibfly_cfg0[105] = ~pcnt210;
assign ibfly_cfg0[106] = ~pcnt212;
assign ibfly_cfg0[107] = ~pcnt214;
assign ibfly_cfg0[108] = ~pcnt216;
assign ibfly_cfg0[109] = ~pcnt218;
assign ibfly_cfg0[110] = ~pcnt220;
assign ibfly_cfg0[111] = ~pcnt222;
assign ibfly_cfg0[112] = ~pcnt224;
assign ibfly_cfg0[113] = ~pcnt226;
assign ibfly_cfg0[114] = ~pcnt228;
assign ibfly_cfg0[115] = ~pcnt230;
assign ibfly_cfg0[116] = ~pcnt232;
assign ibfly_cfg0[117] = ~pcnt234;
assign ibfly_cfg0[118] = ~pcnt236;
assign ibfly_cfg0[119] = ~pcnt238;
assign ibfly_cfg0[120] = ~pcnt240;
assign ibfly_cfg0[121] = ~pcnt242;
assign ibfly_cfg0[122] = ~pcnt244;
assign ibfly_cfg0[123] = ~pcnt246;
assign ibfly_cfg0[124] = ~pcnt248;
assign ibfly_cfg0[125] = ~pcnt250;
assign ibfly_cfg0[126] = ~pcnt252;
assign ibfly_cfg0[127] = ~pcnt254;
endmodule
