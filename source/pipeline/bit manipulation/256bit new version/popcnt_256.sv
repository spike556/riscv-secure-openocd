// population count used in bitmask decoder
// a novel recuisive arch
// Author: Guozhu Xin
// Date:   2018/06/06

module popcnt_2
(
    input   logic [1:0] bitmask,
    output  logic       pcnt0,
    output  logic [1:0] pcnt1
);

assign pcnt0 = bitmask[0];
assign pcnt1 = bitmask[0] + bitmask[1];

endmodule

module popcnt_4
(
    input   logic [3:0] bitmask,
    output  logic       pcnt0,
    output  logic [1:0] pcnt1,
    output  logic       pcnt2,
    output  logic [2:0] pcnt3
);

logic       pcnt0_tmp;
logic [1:0] pcnt1_tmp;

popcnt_2 pop2_i0 (
    .bitmask  (bitmask[1:0]),
    .pcnt0    (pcnt0),
    .pcnt1    (pcnt1)
  );
popcnt_2 pop2_i1 (
    .bitmask  (bitmask[3:2]),
    .pcnt0    (pcnt0_tmp),
    .pcnt1    (pcnt1_tmp)
  );

assign pcnt2 = pcnt0_tmp ^ pcnt1[0];
assign pcnt3 = pcnt1_tmp + pcnt1;

endmodule

module popcnt_8
(
    input   logic [7:0] bitmask,
    output  logic       pcnt0,
    output  logic [1:0] pcnt1,
    output  logic       pcnt2,
    output  logic [2:0] pcnt3,
    output  logic       pcnt4,
    output  logic [1:0] pcnt5,
    output  logic       pcnt6,
    output  logic [3:0] pcnt7
);

logic       pcnt0_tmp;
logic [1:0] pcnt1_tmp;
logic       pcnt2_tmp;
logic [2:0] pcnt3_tmp;

popcnt_4 pop4_i1
(
    .bitmask    (bitmask[3:0]),
    .pcnt0      (pcnt0),
    .pcnt1      (pcnt1),
    .pcnt2      (pcnt2),
    .pcnt3      (pcnt3)
);
popcnt_4 pop4_i2
(
    .bitmask    (bitmask[7:4]),
    .pcnt0      (pcnt0_tmp),
    .pcnt1      (pcnt1_tmp),
    .pcnt2      (pcnt2_tmp),
    .pcnt3      (pcnt3_tmp)
);

assign pcnt4 = pcnt0_tmp ^ pcnt3[0];
assign pcnt5 = pcnt1_tmp + pcnt3[1:0];
assign pcnt6 = pcnt2_tmp ^ pcnt3[0];
assign pcnt7 = pcnt3_tmp + pcnt3;

endmodule

module popcnt_16
(
    input   logic [15:0] bitmask,
    output  logic         pcnt0,
    output  logic [1:0]   pcnt1,
    output  logic         pcnt2,
    output  logic [2:0]   pcnt3,
    output  logic         pcnt4,
    output  logic [1:0]   pcnt5,
    output  logic         pcnt6,
    output  logic [3:0]   pcnt7,
    output  logic         pcnt8,
    output  logic [1:0]   pcnt9,
    output  logic         pcnt10,
    output  logic [2:0]   pcnt11,
    output  logic         pcnt12,
    output  logic [1:0]   pcnt13,
    output  logic         pcnt14,
    output  logic [4:0]   pcnt15
);

logic         pcnt0_tmp;
logic [1:0]   pcnt1_tmp;
logic         pcnt2_tmp;
logic [2:0]   pcnt3_tmp;
logic         pcnt4_tmp;
logic [1:0]   pcnt5_tmp;
logic         pcnt6_tmp;
logic [3:0]   pcnt7_tmp;
popcnt_8 pop8_i1
(
    .bitmask      (bitmask[7:0]),
    .pcnt0        (pcnt0),
    .pcnt1        (pcnt1),
    .pcnt2        (pcnt2),
    .pcnt3        (pcnt3),
    .pcnt4        (pcnt4),
    .pcnt5        (pcnt5),
    .pcnt6        (pcnt6),
    .pcnt7        (pcnt7)
);
popcnt_8 pop8_i2
(
    .bitmask      (bitmask[15:8]),
    .pcnt0        (pcnt0_tmp),
    .pcnt1        (pcnt1_tmp),
    .pcnt2        (pcnt2_tmp),
    .pcnt3        (pcnt3_tmp),
    .pcnt4        (pcnt4_tmp),
    .pcnt5        (pcnt5_tmp),
    .pcnt6        (pcnt6_tmp),
    .pcnt7        (pcnt7_tmp)
);

assign pcnt8  = pcnt0_tmp ^ pcnt7[0];
assign pcnt9  = pcnt1_tmp + pcnt7[1:0];
assign pcnt10 = pcnt2_tmp ^ pcnt7[0];
assign pcnt11 = pcnt3_tmp + pcnt7[2:0];
assign pcnt12 = pcnt4_tmp ^ pcnt7[0];
assign pcnt13 = pcnt5_tmp + pcnt7[1:0];
assign pcnt14 = pcnt6_tmp ^ pcnt7[0];
assign pcnt15 = pcnt7_tmp + pcnt7;

endmodule

module popcnt_32
(
    input   logic [31:0] bitmask,
    output  logic         pcnt0,
    output  logic [1:0]   pcnt1,
    output  logic         pcnt2,
    output  logic [2:0]   pcnt3,
    output  logic         pcnt4,
    output  logic [1:0]   pcnt5,
    output  logic         pcnt6,
    output  logic [3:0]   pcnt7,
    output  logic         pcnt8,
    output  logic [1:0]   pcnt9,
    output  logic         pcnt10,
    output  logic [2:0]   pcnt11,
    output  logic         pcnt12,
    output  logic [1:0]   pcnt13,
    output  logic         pcnt14,
    output  logic [4:0]   pcnt15,
    output  logic         pcnt16,
    output  logic [1:0]   pcnt17,
    output  logic         pcnt18,
    output  logic [2:0]   pcnt19,
    output  logic         pcnt20,
    output  logic [1:0]   pcnt21,
    output  logic         pcnt22,
    output  logic [3:0]   pcnt23,
    output  logic         pcnt24,
    output  logic [1:0]   pcnt25,
    output  logic         pcnt26,
    output  logic [2:0]   pcnt27,
    output  logic         pcnt28,
    output  logic [1:0]   pcnt29,
    output  logic         pcnt30,
    output  logic [5:0]   pcnt31
);

logic         pcnt0_tmp;
logic [1:0]   pcnt1_tmp;
logic         pcnt2_tmp;
logic [2:0]   pcnt3_tmp;
logic         pcnt4_tmp;
logic [1:0]   pcnt5_tmp;
logic         pcnt6_tmp;
logic [3:0]   pcnt7_tmp;
logic         pcnt8_tmp;
logic [1:0]   pcnt9_tmp;
logic         pcnt10_tmp;
logic [2:0]   pcnt11_tmp;
logic         pcnt12_tmp;
logic [1:0]   pcnt13_tmp;
logic         pcnt14_tmp;
logic [4:0]   pcnt15_tmp;

popcnt_16 pop16_i1
(
    .bitmask    (bitmask[15:0]),
    .pcnt0      (pcnt0),
    .pcnt1      (pcnt1),
    .pcnt2      (pcnt2),
    .pcnt3      (pcnt3),
    .pcnt4      (pcnt4),
    .pcnt5      (pcnt5),
    .pcnt6      (pcnt6),
    .pcnt7      (pcnt7),
    .pcnt8      (pcnt8),
    .pcnt9      (pcnt9),
    .pcnt10     (pcnt10),
    .pcnt11     (pcnt11),
    .pcnt12     (pcnt12),
    .pcnt13     (pcnt13),
    .pcnt14     (pcnt14),
    .pcnt15     (pcnt15)
);
popcnt_16 pop16_i2
(
    .bitmask    (bitmask[31:16]),
    .pcnt0      (pcnt0_tmp),
    .pcnt1      (pcnt1_tmp),
    .pcnt2      (pcnt2_tmp),
    .pcnt3      (pcnt3_tmp),
    .pcnt4      (pcnt4_tmp),
    .pcnt5      (pcnt5_tmp),
    .pcnt6      (pcnt6_tmp),
    .pcnt7      (pcnt7_tmp),
    .pcnt8      (pcnt8_tmp),
    .pcnt9      (pcnt9_tmp),
    .pcnt10     (pcnt10_tmp),
    .pcnt11     (pcnt11_tmp),
    .pcnt12     (pcnt12_tmp),
    .pcnt13     (pcnt13_tmp),
    .pcnt14     (pcnt14_tmp),
    .pcnt15     (pcnt15_tmp)
);
assign pcnt16 = pcnt0_tmp ^ pcnt15[0];
assign pcnt17 = pcnt1_tmp + pcnt15[1:0];
assign pcnt18 = pcnt2_tmp ^ pcnt15[0];
assign pcnt19 = pcnt3_tmp + pcnt15[2:0];
assign pcnt20 = pcnt4_tmp ^ pcnt15[0];
assign pcnt21 = pcnt5_tmp + pcnt15[1:0];
assign pcnt22 = pcnt6_tmp ^ pcnt15[0];
assign pcnt23 = pcnt7_tmp + pcnt15[3:0];
assign pcnt24 = pcnt8_tmp ^ pcnt15[0];
assign pcnt25 = pcnt9_tmp + pcnt15[1:0];
assign pcnt26 = pcnt10_tmp ^ pcnt15[0];
assign pcnt27 = pcnt11_tmp + pcnt15[2:0];
assign pcnt28 = pcnt12_tmp ^ pcnt15[0];
assign pcnt29 = pcnt13_tmp + pcnt15[1:0];
assign pcnt30 = pcnt14_tmp ^ pcnt15[0];
assign pcnt31 = pcnt15_tmp + pcnt15;

endmodule

module popcnt_64
(
    input   logic [63:0]  bitmask,
    output  logic         pcnt0,
    output  logic [1:0]   pcnt1,
    output  logic         pcnt2,
    output  logic [2:0]   pcnt3,
    output  logic         pcnt4,
    output  logic [1:0]   pcnt5,
    output  logic         pcnt6,
    output  logic [3:0]   pcnt7,
    output  logic         pcnt8,
    output  logic [1:0]   pcnt9,
    output  logic         pcnt10,
    output  logic [2:0]   pcnt11,
    output  logic         pcnt12,
    output  logic [1:0]   pcnt13,
    output  logic         pcnt14,
    output  logic [4:0]   pcnt15,
    output  logic         pcnt16,
    output  logic [1:0]   pcnt17,
    output  logic         pcnt18,
    output  logic [2:0]   pcnt19,
    output  logic         pcnt20,
    output  logic [1:0]   pcnt21,
    output  logic         pcnt22,
    output  logic [3:0]   pcnt23,
    output  logic         pcnt24,
    output  logic [1:0]   pcnt25,
    output  logic         pcnt26,
    output  logic [2:0]   pcnt27,
    output  logic         pcnt28,
    output  logic [1:0]   pcnt29,
    output  logic         pcnt30,
    output  logic [5:0]   pcnt31,
    output  logic         pcnt32,
    output  logic [1:0]   pcnt33,
    output  logic         pcnt34,
    output  logic [2:0]   pcnt35,
    output  logic         pcnt36,
    output  logic [1:0]   pcnt37,
    output  logic         pcnt38,
    output  logic [3:0]   pcnt39,
    output  logic         pcnt40,
    output  logic [1:0]   pcnt41,
    output  logic         pcnt42,
    output  logic [2:0]   pcnt43,
    output  logic         pcnt44,
    output  logic [1:0]   pcnt45,
    output  logic         pcnt46,
    output  logic [4:0]   pcnt47,
    output  logic         pcnt48,
    output  logic [1:0]   pcnt49,
    output  logic         pcnt50,
    output  logic [2:0]   pcnt51,
    output  logic         pcnt52,
    output  logic [1:0]   pcnt53,
    output  logic         pcnt54,
    output  logic [3:0]   pcnt55,
    output  logic         pcnt56,
    output  logic [1:0]   pcnt57,
    output  logic         pcnt58,
    output  logic [2:0]   pcnt59,
    output  logic         pcnt60,
    output  logic [1:0]   pcnt61,
    output  logic         pcnt62,
    output  logic [6:0]   pcnt63
);
logic         pcnt0_tmp;
logic [1:0]   pcnt1_tmp;
logic         pcnt2_tmp;
logic [2:0]   pcnt3_tmp;
logic         pcnt4_tmp;
logic [1:0]   pcnt5_tmp;
logic         pcnt6_tmp;
logic [3:0]   pcnt7_tmp;
logic         pcnt8_tmp;
logic [1:0]   pcnt9_tmp;
logic         pcnt10_tmp;
logic [2:0]   pcnt11_tmp;
logic         pcnt12_tmp;
logic [1:0]   pcnt13_tmp;
logic         pcnt14_tmp;
logic [4:0]   pcnt15_tmp;
logic         pcnt16_tmp;
logic [1:0]   pcnt17_tmp;
logic         pcnt18_tmp;
logic [2:0]   pcnt19_tmp;
logic         pcnt20_tmp;
logic [1:0]   pcnt21_tmp;
logic         pcnt22_tmp;
logic [3:0]   pcnt23_tmp;
logic         pcnt24_tmp;
logic [1:0]   pcnt25_tmp;
logic         pcnt26_tmp;
logic [2:0]   pcnt27_tmp;
logic         pcnt28_tmp;
logic [1:0]   pcnt29_tmp;
logic         pcnt30_tmp;
logic [5:0]   pcnt31_tmp;

popcnt_32 pop32_i1
(
    .bitmask      (bitmask[31:0]),
    .pcnt0        (pcnt0),
    .pcnt1        (pcnt1),
    .pcnt2        (pcnt2),
    .pcnt3        (pcnt3),
    .pcnt4        (pcnt4),
    .pcnt5        (pcnt5),
    .pcnt6        (pcnt6),
    .pcnt7        (pcnt7),
    .pcnt8        (pcnt8),
    .pcnt9        (pcnt9),
    .pcnt10       (pcnt10),
    .pcnt11       (pcnt11),
    .pcnt12       (pcnt12),
    .pcnt13       (pcnt13),
    .pcnt14       (pcnt14),
    .pcnt15       (pcnt15),
    .pcnt16       (pcnt16),
    .pcnt17       (pcnt17),
    .pcnt18       (pcnt18),
    .pcnt19       (pcnt19),
    .pcnt20       (pcnt20),
    .pcnt21       (pcnt21),
    .pcnt22       (pcnt22),
    .pcnt23       (pcnt23),
    .pcnt24       (pcnt24),
    .pcnt25       (pcnt25),
    .pcnt26       (pcnt26),
    .pcnt27       (pcnt27),
    .pcnt28       (pcnt28),
    .pcnt29       (pcnt29),
    .pcnt30       (pcnt30),
    .pcnt31       (pcnt31)
);
popcnt_32 pop32_i2
(
    .bitmask      (bitmask[63:32]),
    .pcnt0        (pcnt0_tmp),
    .pcnt1        (pcnt1_tmp),
    .pcnt2        (pcnt2_tmp),
    .pcnt3        (pcnt3_tmp),
    .pcnt4        (pcnt4_tmp),
    .pcnt5        (pcnt5_tmp),
    .pcnt6        (pcnt6_tmp),
    .pcnt7        (pcnt7_tmp),
    .pcnt8        (pcnt8_tmp),
    .pcnt9        (pcnt9_tmp),
    .pcnt10       (pcnt10_tmp),
    .pcnt11       (pcnt11_tmp),
    .pcnt12       (pcnt12_tmp),
    .pcnt13       (pcnt13_tmp),
    .pcnt14       (pcnt14_tmp),
    .pcnt15       (pcnt15_tmp),
    .pcnt16       (pcnt16_tmp),
    .pcnt17       (pcnt17_tmp),
    .pcnt18       (pcnt18_tmp),
    .pcnt19       (pcnt19_tmp),
    .pcnt20       (pcnt20_tmp),
    .pcnt21       (pcnt21_tmp),
    .pcnt22       (pcnt22_tmp),
    .pcnt23       (pcnt23_tmp),
    .pcnt24       (pcnt24_tmp),
    .pcnt25       (pcnt25_tmp),
    .pcnt26       (pcnt26_tmp),
    .pcnt27       (pcnt27_tmp),
    .pcnt28       (pcnt28_tmp),
    .pcnt29       (pcnt29_tmp),
    .pcnt30       (pcnt30_tmp),
    .pcnt31       (pcnt31_tmp)
);
assign pcnt32 = pcnt0_tmp ^ pcnt31[0];
assign pcnt33 = pcnt1_tmp + pcnt31[1:0];
assign pcnt34 = pcnt2_tmp ^ pcnt31[0];
assign pcnt35 = pcnt3_tmp + pcnt31[2:0];
assign pcnt36 = pcnt4_tmp ^ pcnt31[0];
assign pcnt37 = pcnt5_tmp + pcnt31[1:0];
assign pcnt38 = pcnt6_tmp ^ pcnt31[0];
assign pcnt39 = pcnt7_tmp + pcnt31[3:0];
assign pcnt40 = pcnt8_tmp ^ pcnt31[0];
assign pcnt41 = pcnt9_tmp + pcnt31[1:0];
assign pcnt42 = pcnt10_tmp ^ pcnt31[0];
assign pcnt43 = pcnt11_tmp + pcnt31[2:0];
assign pcnt44 = pcnt12_tmp ^ pcnt31[0];
assign pcnt45 = pcnt13_tmp + pcnt31[1:0];
assign pcnt46 = pcnt14_tmp ^ pcnt31[0];
assign pcnt47 = pcnt15_tmp + pcnt31[4:0];
assign pcnt48 = pcnt16_tmp ^ pcnt31[0];
assign pcnt49 = pcnt17_tmp + pcnt31[1:0];
assign pcnt50 = pcnt18_tmp ^ pcnt31[0];
assign pcnt51 = pcnt19_tmp + pcnt31[2:0];
assign pcnt52 = pcnt20_tmp ^ pcnt31[0];
assign pcnt53 = pcnt21_tmp + pcnt31[1:0];
assign pcnt54 = pcnt22_tmp ^ pcnt31[0];
assign pcnt55 = pcnt23_tmp + pcnt31[3:0];
assign pcnt56 = pcnt24_tmp ^ pcnt31[0];
assign pcnt57 = pcnt25_tmp + pcnt31[1:0];
assign pcnt58 = pcnt26_tmp ^ pcnt31[0];
assign pcnt59 = pcnt27_tmp + pcnt31[2:0];
assign pcnt60 = pcnt28_tmp ^ pcnt31[0];
assign pcnt61 = pcnt29_tmp + pcnt31[1:0];
assign pcnt62 = pcnt30_tmp ^ pcnt31[0];
assign pcnt63 = pcnt31_tmp + pcnt31;
endmodule

module popcnt_128
(
    input   logic [127:0]  bitmask,
    output  logic         pcnt0,
    output  logic [1:0]   pcnt1,
    output  logic         pcnt2,
    output  logic [2:0]   pcnt3,
    output  logic         pcnt4,
    output  logic [1:0]   pcnt5,
    output  logic         pcnt6,
    output  logic [3:0]   pcnt7,
    output  logic         pcnt8,
    output  logic [1:0]   pcnt9,
    output  logic         pcnt10,
    output  logic [2:0]   pcnt11,
    output  logic         pcnt12,
    output  logic [1:0]   pcnt13,
    output  logic         pcnt14,
    output  logic [4:0]   pcnt15,
    output  logic         pcnt16,
    output  logic [1:0]   pcnt17,
    output  logic         pcnt18,
    output  logic [2:0]   pcnt19,
    output  logic         pcnt20,
    output  logic [1:0]   pcnt21,
    output  logic         pcnt22,
    output  logic [3:0]   pcnt23,
    output  logic         pcnt24,
    output  logic [1:0]   pcnt25,
    output  logic         pcnt26,
    output  logic [2:0]   pcnt27,
    output  logic         pcnt28,
    output  logic [1:0]   pcnt29,
    output  logic         pcnt30,
    output  logic [5:0]   pcnt31,
    output  logic         pcnt32,
    output  logic [1:0]   pcnt33,
    output  logic         pcnt34,
    output  logic [2:0]   pcnt35,
    output  logic         pcnt36,
    output  logic [1:0]   pcnt37,
    output  logic         pcnt38,
    output  logic [3:0]   pcnt39,
    output  logic         pcnt40,
    output  logic [1:0]   pcnt41,
    output  logic         pcnt42,
    output  logic [2:0]   pcnt43,
    output  logic         pcnt44,
    output  logic [1:0]   pcnt45,
    output  logic         pcnt46,
    output  logic [4:0]   pcnt47,
    output  logic         pcnt48,
    output  logic [1:0]   pcnt49,
    output  logic         pcnt50,
    output  logic [2:0]   pcnt51,
    output  logic         pcnt52,
    output  logic [1:0]   pcnt53,
    output  logic         pcnt54,
    output  logic [3:0]   pcnt55,
    output  logic         pcnt56,
    output  logic [1:0]   pcnt57,
    output  logic         pcnt58,
    output  logic [2:0]   pcnt59,
    output  logic         pcnt60,
    output  logic [1:0]   pcnt61,
    output  logic         pcnt62,
    output  logic [6:0]   pcnt63,
    output  logic         pcnt64,
    output  logic [1:0]   pcnt65,
    output  logic         pcnt66,
    output  logic [2:0]   pcnt67,
    output  logic         pcnt68,
    output  logic [1:0]   pcnt69,
    output  logic         pcnt70,
    output  logic [3:0]   pcnt71,
    output  logic         pcnt72,
    output  logic [1:0]   pcnt73,
    output  logic         pcnt74,
    output  logic [2:0]   pcnt75,
    output  logic         pcnt76,
    output  logic [1:0]   pcnt77,
    output  logic         pcnt78,
    output  logic [4:0]   pcnt79,
    output  logic         pcnt80,
    output  logic [1:0]   pcnt81,
    output  logic         pcnt82,
    output  logic [2:0]   pcnt83,
    output  logic         pcnt84,
    output  logic [1:0]   pcnt85,
    output  logic         pcnt86,
    output  logic [3:0]   pcnt87,
    output  logic         pcnt88,
    output  logic [1:0]   pcnt89,
    output  logic         pcnt90,
    output  logic [2:0]   pcnt91,
    output  logic         pcnt92,
    output  logic [1:0]   pcnt93,
    output  logic         pcnt94,
    output  logic [5:0]   pcnt95,
    output  logic         pcnt96,
    output  logic [1:0]   pcnt97,
    output  logic         pcnt98,
    output  logic [2:0]   pcnt99,
    output  logic         pcnt100,
    output  logic [1:0]   pcnt101,
    output  logic         pcnt102,
    output  logic [3:0]   pcnt103,
    output  logic         pcnt104,
    output  logic [1:0]   pcnt105,
    output  logic         pcnt106,
    output  logic [2:0]   pcnt107,
    output  logic         pcnt108,
    output  logic [1:0]   pcnt109,
    output  logic         pcnt110,
    output  logic [4:0]   pcnt111,
    output  logic         pcnt112,
    output  logic [1:0]   pcnt113,
    output  logic         pcnt114,
    output  logic [2:0]   pcnt115,
    output  logic         pcnt116,
    output  logic [1:0]   pcnt117,
    output  logic         pcnt118,
    output  logic [3:0]   pcnt119,
    output  logic         pcnt120,
    output  logic [1:0]   pcnt121,
    output  logic         pcnt122,
    output  logic [2:0]   pcnt123,
    output  logic         pcnt124,
    output  logic [1:0]   pcnt125,
    output  logic         pcnt126,
    output  logic [7:0]   pcnt127
);
logic         pcnt0_tmp;
logic [1:0]   pcnt1_tmp;
logic         pcnt2_tmp;
logic [2:0]   pcnt3_tmp;
logic         pcnt4_tmp;
logic [1:0]   pcnt5_tmp;
logic         pcnt6_tmp;
logic [3:0]   pcnt7_tmp;
logic         pcnt8_tmp;
logic [1:0]   pcnt9_tmp;
logic         pcnt10_tmp;
logic [2:0]   pcnt11_tmp;
logic         pcnt12_tmp;
logic [1:0]   pcnt13_tmp;
logic         pcnt14_tmp;
logic [4:0]   pcnt15_tmp;
logic         pcnt16_tmp;
logic [1:0]   pcnt17_tmp;
logic         pcnt18_tmp;
logic [2:0]   pcnt19_tmp;
logic         pcnt20_tmp;
logic [1:0]   pcnt21_tmp;
logic         pcnt22_tmp;
logic [3:0]   pcnt23_tmp;
logic         pcnt24_tmp;
logic [1:0]   pcnt25_tmp;
logic         pcnt26_tmp;
logic [2:0]   pcnt27_tmp;
logic         pcnt28_tmp;
logic [1:0]   pcnt29_tmp;
logic         pcnt30_tmp;
logic [5:0]   pcnt31_tmp;
logic         pcnt32_tmp;
logic [1:0]   pcnt33_tmp;
logic         pcnt34_tmp;
logic [2:0]   pcnt35_tmp;
logic         pcnt36_tmp;
logic [1:0]   pcnt37_tmp;
logic         pcnt38_tmp;
logic [3:0]   pcnt39_tmp;
logic         pcnt40_tmp;
logic [1:0]   pcnt41_tmp;
logic         pcnt42_tmp;
logic [2:0]   pcnt43_tmp;
logic         pcnt44_tmp;
logic [1:0]   pcnt45_tmp;
logic         pcnt46_tmp;
logic [4:0]   pcnt47_tmp;
logic         pcnt48_tmp;
logic [1:0]   pcnt49_tmp;
logic         pcnt50_tmp;
logic [2:0]   pcnt51_tmp;
logic         pcnt52_tmp;
logic [1:0]   pcnt53_tmp;
logic         pcnt54_tmp;
logic [3:0]   pcnt55_tmp;
logic         pcnt56_tmp;
logic [1:0]   pcnt57_tmp;
logic         pcnt58_tmp;
logic [2:0]   pcnt59_tmp;
logic         pcnt60_tmp;
logic [1:0]   pcnt61_tmp;
logic         pcnt62_tmp;
logic [6:0]   pcnt63_tmp;

popcnt_64 pop64_i1
(
    .bitmask      (bitmask[63:0]),
    .pcnt0        (pcnt0),
    .pcnt1        (pcnt1),
    .pcnt2        (pcnt2),
    .pcnt3        (pcnt3),
    .pcnt4        (pcnt4),
    .pcnt5        (pcnt5),
    .pcnt6        (pcnt6),
    .pcnt7        (pcnt7),
    .pcnt8        (pcnt8),
    .pcnt9        (pcnt9),
    .pcnt10       (pcnt10),
    .pcnt11       (pcnt11),
    .pcnt12       (pcnt12),
    .pcnt13       (pcnt13),
    .pcnt14       (pcnt14),
    .pcnt15       (pcnt15),
    .pcnt16       (pcnt16),
    .pcnt17       (pcnt17),
    .pcnt18       (pcnt18),
    .pcnt19       (pcnt19),
    .pcnt20       (pcnt20),
    .pcnt21       (pcnt21),
    .pcnt22       (pcnt22),
    .pcnt23       (pcnt23),
    .pcnt24       (pcnt24),
    .pcnt25       (pcnt25),
    .pcnt26       (pcnt26),
    .pcnt27       (pcnt27),
    .pcnt28       (pcnt28),
    .pcnt29       (pcnt29),
    .pcnt30       (pcnt30),
    .pcnt31       (pcnt31),
    .pcnt32       (pcnt32),
    .pcnt33       (pcnt33),
    .pcnt34       (pcnt34),
    .pcnt35       (pcnt35),
    .pcnt36       (pcnt36),
    .pcnt37       (pcnt37),
    .pcnt38       (pcnt38),
    .pcnt39       (pcnt39),
    .pcnt40       (pcnt40),
    .pcnt41       (pcnt41),
    .pcnt42       (pcnt42),
    .pcnt43       (pcnt43),
    .pcnt44       (pcnt44),
    .pcnt45       (pcnt45),
    .pcnt46       (pcnt46),
    .pcnt47       (pcnt47),
    .pcnt48       (pcnt48),
    .pcnt49       (pcnt49),
    .pcnt50       (pcnt50),
    .pcnt51       (pcnt51),
    .pcnt52       (pcnt52),
    .pcnt53       (pcnt53),
    .pcnt54       (pcnt54),
    .pcnt55       (pcnt55),
    .pcnt56       (pcnt56),
    .pcnt57       (pcnt57),
    .pcnt58       (pcnt58),
    .pcnt59       (pcnt59),
    .pcnt60       (pcnt60),
    .pcnt61       (pcnt61),
    .pcnt62       (pcnt62),
    .pcnt63       (pcnt63)
);
popcnt_64 pop64_i2
(
    .bitmask      (bitmask[127:64]),
    .pcnt0        (pcnt0_tmp),
    .pcnt1        (pcnt1_tmp),
    .pcnt2        (pcnt2_tmp),
    .pcnt3        (pcnt3_tmp),
    .pcnt4        (pcnt4_tmp),
    .pcnt5        (pcnt5_tmp),
    .pcnt6        (pcnt6_tmp),
    .pcnt7        (pcnt7_tmp),
    .pcnt8        (pcnt8_tmp),
    .pcnt9        (pcnt9_tmp),
    .pcnt10       (pcnt10_tmp),
    .pcnt11       (pcnt11_tmp),
    .pcnt12       (pcnt12_tmp),
    .pcnt13       (pcnt13_tmp),
    .pcnt14       (pcnt14_tmp),
    .pcnt15       (pcnt15_tmp),
    .pcnt16       (pcnt16_tmp),
    .pcnt17       (pcnt17_tmp),
    .pcnt18       (pcnt18_tmp),
    .pcnt19       (pcnt19_tmp),
    .pcnt20       (pcnt20_tmp),
    .pcnt21       (pcnt21_tmp),
    .pcnt22       (pcnt22_tmp),
    .pcnt23       (pcnt23_tmp),
    .pcnt24       (pcnt24_tmp),
    .pcnt25       (pcnt25_tmp),
    .pcnt26       (pcnt26_tmp),
    .pcnt27       (pcnt27_tmp),
    .pcnt28       (pcnt28_tmp),
    .pcnt29       (pcnt29_tmp),
    .pcnt30       (pcnt30_tmp),
    .pcnt31       (pcnt31_tmp),
    .pcnt32       (pcnt32_tmp),
    .pcnt33       (pcnt33_tmp),
    .pcnt34       (pcnt34_tmp),
    .pcnt35       (pcnt35_tmp),
    .pcnt36       (pcnt36_tmp),
    .pcnt37       (pcnt37_tmp),
    .pcnt38       (pcnt38_tmp),
    .pcnt39       (pcnt39_tmp),
    .pcnt40       (pcnt40_tmp),
    .pcnt41       (pcnt41_tmp),
    .pcnt42       (pcnt42_tmp),
    .pcnt43       (pcnt43_tmp),
    .pcnt44       (pcnt44_tmp),
    .pcnt45       (pcnt45_tmp),
    .pcnt46       (pcnt46_tmp),
    .pcnt47       (pcnt47_tmp),
    .pcnt48       (pcnt48_tmp),
    .pcnt49       (pcnt49_tmp),
    .pcnt50       (pcnt50_tmp),
    .pcnt51       (pcnt51_tmp),
    .pcnt52       (pcnt52_tmp),
    .pcnt53       (pcnt53_tmp),
    .pcnt54       (pcnt54_tmp),
    .pcnt55       (pcnt55_tmp),
    .pcnt56       (pcnt56_tmp),
    .pcnt57       (pcnt57_tmp),
    .pcnt58       (pcnt58_tmp),
    .pcnt59       (pcnt59_tmp),
    .pcnt60       (pcnt60_tmp),
    .pcnt61       (pcnt61_tmp),
    .pcnt62       (pcnt62_tmp),
    .pcnt63       (pcnt63_tmp)
);

assign pcnt64 = pcnt0_tmp ^ pcnt63[0];
assign pcnt65 = pcnt1_tmp + pcnt63[1:0];
assign pcnt66 = pcnt2_tmp ^ pcnt63[0];
assign pcnt67 = pcnt3_tmp + pcnt63[2:0];
assign pcnt68 = pcnt4_tmp ^ pcnt63[0];
assign pcnt69 = pcnt5_tmp + pcnt63[1:0];
assign pcnt70 = pcnt6_tmp ^ pcnt63[0];
assign pcnt71 = pcnt7_tmp + pcnt63[3:0];
assign pcnt72 = pcnt8_tmp ^ pcnt63[0];
assign pcnt73 = pcnt9_tmp + pcnt63[1:0];
assign pcnt74 = pcnt10_tmp ^ pcnt63[0];
assign pcnt75 = pcnt11_tmp + pcnt63[2:0];
assign pcnt76 = pcnt12_tmp ^ pcnt63[0];
assign pcnt77 = pcnt13_tmp + pcnt63[1:0];
assign pcnt78 = pcnt14_tmp ^ pcnt63[0];
assign pcnt79 = pcnt15_tmp + pcnt63[4:0];
assign pcnt80 = pcnt16_tmp ^ pcnt63[0];
assign pcnt81 = pcnt17_tmp + pcnt63[1:0];
assign pcnt82 = pcnt18_tmp ^ pcnt63[0];
assign pcnt83 = pcnt19_tmp + pcnt63[2:0];
assign pcnt84 = pcnt20_tmp ^ pcnt63[0];
assign pcnt85 = pcnt21_tmp + pcnt63[1:0];
assign pcnt86 = pcnt22_tmp ^ pcnt63[0];
assign pcnt87 = pcnt23_tmp + pcnt63[3:0];
assign pcnt88 = pcnt24_tmp ^ pcnt63[0];
assign pcnt89 = pcnt25_tmp + pcnt63[1:0];
assign pcnt90 = pcnt26_tmp ^ pcnt63[0];
assign pcnt91 = pcnt27_tmp + pcnt63[2:0];
assign pcnt92 = pcnt28_tmp ^ pcnt63[0];
assign pcnt93 = pcnt29_tmp + pcnt63[1:0];
assign pcnt94 = pcnt30_tmp ^ pcnt63[0];
assign pcnt95 = pcnt31_tmp + pcnt63[5:0];
assign pcnt96 = pcnt32_tmp ^ pcnt63[0];
assign pcnt97 = pcnt33_tmp + pcnt63[1:0];
assign pcnt98 = pcnt34_tmp ^ pcnt63[0];
assign pcnt99 = pcnt35_tmp + pcnt63[2:0];
assign pcnt100 = pcnt36_tmp ^ pcnt63[0];
assign pcnt101 = pcnt37_tmp + pcnt63[1:0];
assign pcnt102 = pcnt38_tmp ^ pcnt63[0];
assign pcnt103 = pcnt39_tmp + pcnt63[3:0];
assign pcnt104 = pcnt40_tmp ^ pcnt63[0];
assign pcnt105 = pcnt41_tmp + pcnt63[1:0];
assign pcnt106 = pcnt42_tmp ^ pcnt63[0];
assign pcnt107 = pcnt43_tmp + pcnt63[2:0];
assign pcnt108 = pcnt44_tmp ^ pcnt63[0];
assign pcnt109 = pcnt45_tmp + pcnt63[1:0];
assign pcnt110 = pcnt46_tmp ^ pcnt63[0];
assign pcnt111 = pcnt47_tmp + pcnt63[4:0];
assign pcnt112 = pcnt48_tmp ^ pcnt63[0];
assign pcnt113 = pcnt49_tmp + pcnt63[1:0];
assign pcnt114 = pcnt50_tmp ^ pcnt63[0];
assign pcnt115 = pcnt51_tmp + pcnt63[2:0];
assign pcnt116 = pcnt52_tmp ^ pcnt63[0];
assign pcnt117 = pcnt53_tmp + pcnt63[1:0];
assign pcnt118 = pcnt54_tmp ^ pcnt63[0];
assign pcnt119 = pcnt55_tmp + pcnt63[3:0];
assign pcnt120 = pcnt56_tmp ^ pcnt63[0];
assign pcnt121 = pcnt57_tmp + pcnt63[1:0];
assign pcnt122 = pcnt58_tmp ^ pcnt63[0];
assign pcnt123 = pcnt59_tmp + pcnt63[2:0];
assign pcnt124 = pcnt60_tmp ^ pcnt63[0];
assign pcnt125 = pcnt61_tmp + pcnt63[1:0];
assign pcnt126 = pcnt62_tmp ^ pcnt63[0];
assign pcnt127 = pcnt63_tmp + pcnt63;
endmodule

module popcnt_256
(
    input   logic [255:0] bitmask,
    output  logic         pcnt0,
    output  logic [1:0]   pcnt1,
    output  logic         pcnt2,
    output  logic [2:0]   pcnt3,
    output  logic         pcnt4,
    output  logic [1:0]   pcnt5,
    output  logic         pcnt6,
    output  logic [3:0]   pcnt7,
    output  logic         pcnt8,
    output  logic [1:0]   pcnt9,
    output  logic         pcnt10,
    output  logic [2:0]   pcnt11,
    output  logic         pcnt12,
    output  logic [1:0]   pcnt13,
    output  logic         pcnt14,
    output  logic [4:0]   pcnt15,
    output  logic         pcnt16,
    output  logic [1:0]   pcnt17,
    output  logic         pcnt18,
    output  logic [2:0]   pcnt19,
    output  logic         pcnt20,
    output  logic [1:0]   pcnt21,
    output  logic         pcnt22,
    output  logic [3:0]   pcnt23,
    output  logic         pcnt24,
    output  logic [1:0]   pcnt25,
    output  logic         pcnt26,
    output  logic [2:0]   pcnt27,
    output  logic         pcnt28,
    output  logic [1:0]   pcnt29,
    output  logic         pcnt30,
    output  logic [5:0]   pcnt31,
    output  logic         pcnt32,
    output  logic [1:0]   pcnt33,
    output  logic         pcnt34,
    output  logic [2:0]   pcnt35,
    output  logic         pcnt36,
    output  logic [1:0]   pcnt37,
    output  logic         pcnt38,
    output  logic [3:0]   pcnt39,
    output  logic         pcnt40,
    output  logic [1:0]   pcnt41,
    output  logic         pcnt42,
    output  logic [2:0]   pcnt43,
    output  logic         pcnt44,
    output  logic [1:0]   pcnt45,
    output  logic         pcnt46,
    output  logic [4:0]   pcnt47,
    output  logic         pcnt48,
    output  logic [1:0]   pcnt49,
    output  logic         pcnt50,
    output  logic [2:0]   pcnt51,
    output  logic         pcnt52,
    output  logic [1:0]   pcnt53,
    output  logic         pcnt54,
    output  logic [3:0]   pcnt55,
    output  logic         pcnt56,
    output  logic [1:0]   pcnt57,
    output  logic         pcnt58,
    output  logic [2:0]   pcnt59,
    output  logic         pcnt60,
    output  logic [1:0]   pcnt61,
    output  logic         pcnt62,
    output  logic [6:0]   pcnt63,
    output  logic         pcnt64,
    output  logic [1:0]   pcnt65,
    output  logic         pcnt66,
    output  logic [2:0]   pcnt67,
    output  logic         pcnt68,
    output  logic [1:0]   pcnt69,
    output  logic         pcnt70,
    output  logic [3:0]   pcnt71,
    output  logic         pcnt72,
    output  logic [1:0]   pcnt73,
    output  logic         pcnt74,
    output  logic [2:0]   pcnt75,
    output  logic         pcnt76,
    output  logic [1:0]   pcnt77,
    output  logic         pcnt78,
    output  logic [4:0]   pcnt79,
    output  logic         pcnt80,
    output  logic [1:0]   pcnt81,
    output  logic         pcnt82,
    output  logic [2:0]   pcnt83,
    output  logic         pcnt84,
    output  logic [1:0]   pcnt85,
    output  logic         pcnt86,
    output  logic [3:0]   pcnt87,
    output  logic         pcnt88,
    output  logic [1:0]   pcnt89,
    output  logic         pcnt90,
    output  logic [2:0]   pcnt91,
    output  logic         pcnt92,
    output  logic [1:0]   pcnt93,
    output  logic         pcnt94,
    output  logic [5:0]   pcnt95,
    output  logic         pcnt96,
    output  logic [1:0]   pcnt97,
    output  logic         pcnt98,
    output  logic [2:0]   pcnt99,
    output  logic         pcnt100,
    output  logic [1:0]   pcnt101,
    output  logic         pcnt102,
    output  logic [3:0]   pcnt103,
    output  logic         pcnt104,
    output  logic [1:0]   pcnt105,
    output  logic         pcnt106,
    output  logic [2:0]   pcnt107,
    output  logic         pcnt108,
    output  logic [1:0]   pcnt109,
    output  logic         pcnt110,
    output  logic [4:0]   pcnt111,
    output  logic         pcnt112,
    output  logic [1:0]   pcnt113,
    output  logic         pcnt114,
    output  logic [2:0]   pcnt115,
    output  logic         pcnt116,
    output  logic [1:0]   pcnt117,
    output  logic         pcnt118,
    output  logic [3:0]   pcnt119,
    output  logic         pcnt120,
    output  logic [1:0]   pcnt121,
    output  logic         pcnt122,
    output  logic [2:0]   pcnt123,
    output  logic         pcnt124,
    output  logic [1:0]   pcnt125,
    output  logic         pcnt126,
    output  logic [7:0]   pcnt127,
    output  logic         pcnt128,
    output  logic [1:0]   pcnt129,
    output  logic         pcnt130,
    output  logic [2:0]   pcnt131,
    output  logic         pcnt132,
    output  logic [1:0]   pcnt133,
    output  logic         pcnt134,
    output  logic [3:0]   pcnt135,
    output  logic         pcnt136,
    output  logic [1:0]   pcnt137,
    output  logic         pcnt138,
    output  logic [2:0]   pcnt139,
    output  logic         pcnt140,
    output  logic [1:0]   pcnt141,
    output  logic         pcnt142,
    output  logic [4:0]   pcnt143,
    output  logic         pcnt144,
    output  logic [1:0]   pcnt145,
    output  logic         pcnt146,
    output  logic [2:0]   pcnt147,
    output  logic         pcnt148,
    output  logic [1:0]   pcnt149,
    output  logic         pcnt150,
    output  logic [3:0]   pcnt151,
    output  logic         pcnt152,
    output  logic [1:0]   pcnt153,
    output  logic         pcnt154,
    output  logic [2:0]   pcnt155,
    output  logic         pcnt156,
    output  logic [1:0]   pcnt157,
    output  logic         pcnt158,
    output  logic [5:0]   pcnt159,
    output  logic         pcnt160,
    output  logic [1:0]   pcnt161,
    output  logic         pcnt162,
    output  logic [2:0]   pcnt163,
    output  logic         pcnt164,
    output  logic [1:0]   pcnt165,
    output  logic         pcnt166,
    output  logic [3:0]   pcnt167,
    output  logic         pcnt168,
    output  logic [1:0]   pcnt169,
    output  logic         pcnt170,
    output  logic [2:0]   pcnt171,
    output  logic         pcnt172,
    output  logic [1:0]   pcnt173,
    output  logic         pcnt174,
    output  logic [4:0]   pcnt175,
    output  logic         pcnt176,
    output  logic [1:0]   pcnt177,
    output  logic         pcnt178,
    output  logic [2:0]   pcnt179,
    output  logic         pcnt180,
    output  logic [1:0]   pcnt181,
    output  logic         pcnt182,
    output  logic [3:0]   pcnt183,
    output  logic         pcnt184,
    output  logic [1:0]   pcnt185,
    output  logic         pcnt186,
    output  logic [2:0]   pcnt187,
    output  logic         pcnt188,
    output  logic [1:0]   pcnt189,
    output  logic         pcnt190,
    output  logic [6:0]   pcnt191,
    output  logic         pcnt192,
    output  logic [1:0]   pcnt193,
    output  logic         pcnt194,
    output  logic [2:0]   pcnt195,
    output  logic         pcnt196,
    output  logic [1:0]   pcnt197,
    output  logic         pcnt198,
    output  logic [3:0]   pcnt199,
    output  logic         pcnt200,
    output  logic [1:0]   pcnt201,
    output  logic         pcnt202,
    output  logic [2:0]   pcnt203,
    output  logic         pcnt204,
    output  logic [1:0]   pcnt205,
    output  logic         pcnt206,
    output  logic [4:0]   pcnt207,
    output  logic         pcnt208,
    output  logic [1:0]   pcnt209,
    output  logic         pcnt210,
    output  logic [2:0]   pcnt211,
    output  logic         pcnt212,
    output  logic [1:0]   pcnt213,
    output  logic         pcnt214,
    output  logic [3:0]   pcnt215,
    output  logic         pcnt216,
    output  logic [1:0]   pcnt217,
    output  logic         pcnt218,
    output  logic [2:0]   pcnt219,
    output  logic         pcnt220,
    output  logic [1:0]   pcnt221,
    output  logic         pcnt222,
    output  logic [5:0]   pcnt223,
    output  logic         pcnt224,
    output  logic [1:0]   pcnt225,
    output  logic         pcnt226,
    output  logic [2:0]   pcnt227,
    output  logic         pcnt228,
    output  logic [1:0]   pcnt229,
    output  logic         pcnt230,
    output  logic [3:0]   pcnt231,
    output  logic         pcnt232,
    output  logic [1:0]   pcnt233,
    output  logic         pcnt234,
    output  logic [2:0]   pcnt235,
    output  logic         pcnt236,
    output  logic [1:0]   pcnt237,
    output  logic         pcnt238,
    output  logic [4:0]   pcnt239,
    output  logic         pcnt240,
    output  logic [1:0]   pcnt241,
    output  logic         pcnt242,
    output  logic [2:0]   pcnt243,
    output  logic         pcnt244,
    output  logic [1:0]   pcnt245,
    output  logic         pcnt246,
    output  logic [3:0]   pcnt247,
    output  logic         pcnt248,
    output  logic [1:0]   pcnt249,
    output  logic         pcnt250,
    output  logic [2:0]   pcnt251,
    output  logic         pcnt252,
    output  logic [1:0]   pcnt253,
    output  logic         pcnt254
    //output  logic [8:0]   pcnt255
);

logic         pcnt0_tmp;
logic [1:0]   pcnt1_tmp;
logic         pcnt2_tmp;
logic [2:0]   pcnt3_tmp;
logic         pcnt4_tmp;
logic [1:0]   pcnt5_tmp;
logic         pcnt6_tmp;
logic [3:0]   pcnt7_tmp;
logic         pcnt8_tmp;
logic [1:0]   pcnt9_tmp;
logic         pcnt10_tmp;
logic [2:0]   pcnt11_tmp;
logic         pcnt12_tmp;
logic [1:0]   pcnt13_tmp;
logic         pcnt14_tmp;
logic [4:0]   pcnt15_tmp;
logic         pcnt16_tmp;
logic [1:0]   pcnt17_tmp;
logic         pcnt18_tmp;
logic [2:0]   pcnt19_tmp;
logic         pcnt20_tmp;
logic [1:0]   pcnt21_tmp;
logic         pcnt22_tmp;
logic [3:0]   pcnt23_tmp;
logic         pcnt24_tmp;
logic [1:0]   pcnt25_tmp;
logic         pcnt26_tmp;
logic [2:0]   pcnt27_tmp;
logic         pcnt28_tmp;
logic [1:0]   pcnt29_tmp;
logic         pcnt30_tmp;
logic [5:0]   pcnt31_tmp;
logic         pcnt32_tmp;
logic [1:0]   pcnt33_tmp;
logic         pcnt34_tmp;
logic [2:0]   pcnt35_tmp;
logic         pcnt36_tmp;
logic [1:0]   pcnt37_tmp;
logic         pcnt38_tmp;
logic [3:0]   pcnt39_tmp;
logic         pcnt40_tmp;
logic [1:0]   pcnt41_tmp;
logic         pcnt42_tmp;
logic [2:0]   pcnt43_tmp;
logic         pcnt44_tmp;
logic [1:0]   pcnt45_tmp;
logic         pcnt46_tmp;
logic [4:0]   pcnt47_tmp;
logic         pcnt48_tmp;
logic [1:0]   pcnt49_tmp;
logic         pcnt50_tmp;
logic [2:0]   pcnt51_tmp;
logic         pcnt52_tmp;
logic [1:0]   pcnt53_tmp;
logic         pcnt54_tmp;
logic [3:0]   pcnt55_tmp;
logic         pcnt56_tmp;
logic [1:0]   pcnt57_tmp;
logic         pcnt58_tmp;
logic [2:0]   pcnt59_tmp;
logic         pcnt60_tmp;
logic [1:0]   pcnt61_tmp;
logic         pcnt62_tmp;
logic [6:0]   pcnt63_tmp;
logic         pcnt64_tmp;
logic [1:0]   pcnt65_tmp;
logic         pcnt66_tmp;
logic [2:0]   pcnt67_tmp;
logic         pcnt68_tmp;
logic [1:0]   pcnt69_tmp;
logic         pcnt70_tmp;
logic [3:0]   pcnt71_tmp;
logic         pcnt72_tmp;
logic [1:0]   pcnt73_tmp;
logic         pcnt74_tmp;
logic [2:0]   pcnt75_tmp;
logic         pcnt76_tmp;
logic [1:0]   pcnt77_tmp;
logic         pcnt78_tmp;
logic [4:0]   pcnt79_tmp;
logic         pcnt80_tmp;
logic [1:0]   pcnt81_tmp;
logic         pcnt82_tmp;
logic [2:0]   pcnt83_tmp;
logic         pcnt84_tmp;
logic [1:0]   pcnt85_tmp;
logic         pcnt86_tmp;
logic [3:0]   pcnt87_tmp;
logic         pcnt88_tmp;
logic [1:0]   pcnt89_tmp;
logic         pcnt90_tmp;
logic [2:0]   pcnt91_tmp;
logic         pcnt92_tmp;
logic [1:0]   pcnt93_tmp;
logic         pcnt94_tmp;
logic [5:0]   pcnt95_tmp;
logic         pcnt96_tmp;
logic [1:0]   pcnt97_tmp;
logic         pcnt98_tmp;
logic [2:0]   pcnt99_tmp;
logic         pcnt100_tmp;
logic [1:0]   pcnt101_tmp;
logic         pcnt102_tmp;
logic [3:0]   pcnt103_tmp;
logic         pcnt104_tmp;
logic [1:0]   pcnt105_tmp;
logic         pcnt106_tmp;
logic [2:0]   pcnt107_tmp;
logic         pcnt108_tmp;
logic [1:0]   pcnt109_tmp;
logic         pcnt110_tmp;
logic [4:0]   pcnt111_tmp;
logic         pcnt112_tmp;
logic [1:0]   pcnt113_tmp;
logic         pcnt114_tmp;
logic [2:0]   pcnt115_tmp;
logic         pcnt116_tmp;
logic [1:0]   pcnt117_tmp;
logic         pcnt118_tmp;
logic [3:0]   pcnt119_tmp;
logic         pcnt120_tmp;
logic [1:0]   pcnt121_tmp;
logic         pcnt122_tmp;
logic [2:0]   pcnt123_tmp;
logic         pcnt124_tmp;
logic [1:0]   pcnt125_tmp;
logic         pcnt126_tmp;
logic [7:0]   pcnt127_tmp;

popcnt_128 pop128_i1
(
    .bitmask    (bitmask[127:0]),
    .pcnt0      (pcnt0),
    .pcnt1      (pcnt1),
    .pcnt2      (pcnt2),
    .pcnt3      (pcnt3),
    .pcnt4      (pcnt4),
    .pcnt5      (pcnt5),
    .pcnt6      (pcnt6),
    .pcnt7      (pcnt7),
    .pcnt8      (pcnt8),
    .pcnt9      (pcnt9),
    .pcnt10     (pcnt10),
    .pcnt11     (pcnt11),
    .pcnt12     (pcnt12),
    .pcnt13     (pcnt13),
    .pcnt14     (pcnt14),
    .pcnt15     (pcnt15),
    .pcnt16     (pcnt16),
    .pcnt17     (pcnt17),
    .pcnt18     (pcnt18),
    .pcnt19     (pcnt19),
    .pcnt20     (pcnt20),
    .pcnt21     (pcnt21),
    .pcnt22     (pcnt22),
    .pcnt23     (pcnt23),
    .pcnt24     (pcnt24),
    .pcnt25     (pcnt25),
    .pcnt26     (pcnt26),
    .pcnt27     (pcnt27),
    .pcnt28     (pcnt28),
    .pcnt29     (pcnt29),
    .pcnt30     (pcnt30),
    .pcnt31     (pcnt31),
    .pcnt32     (pcnt32),
    .pcnt33     (pcnt33),
    .pcnt34     (pcnt34),
    .pcnt35     (pcnt35),
    .pcnt36     (pcnt36),
    .pcnt37     (pcnt37),
    .pcnt38     (pcnt38),
    .pcnt39     (pcnt39),
    .pcnt40     (pcnt40),
    .pcnt41     (pcnt41),
    .pcnt42     (pcnt42),
    .pcnt43     (pcnt43),
    .pcnt44     (pcnt44),
    .pcnt45     (pcnt45),
    .pcnt46     (pcnt46),
    .pcnt47     (pcnt47),
    .pcnt48     (pcnt48),
    .pcnt49     (pcnt49),
    .pcnt50     (pcnt50),
    .pcnt51     (pcnt51),
    .pcnt52     (pcnt52),
    .pcnt53     (pcnt53),
    .pcnt54     (pcnt54),
    .pcnt55     (pcnt55),
    .pcnt56     (pcnt56),
    .pcnt57     (pcnt57),
    .pcnt58     (pcnt58),
    .pcnt59     (pcnt59),
    .pcnt60     (pcnt60),
    .pcnt61     (pcnt61),
    .pcnt62     (pcnt62),
    .pcnt63     (pcnt63),
    .pcnt64     (pcnt64),
    .pcnt65     (pcnt65),
    .pcnt66     (pcnt66),
    .pcnt67     (pcnt67),
    .pcnt68     (pcnt68),
    .pcnt69     (pcnt69),
    .pcnt70     (pcnt70),
    .pcnt71     (pcnt71),
    .pcnt72     (pcnt72),
    .pcnt73     (pcnt73),
    .pcnt74     (pcnt74),
    .pcnt75     (pcnt75),
    .pcnt76     (pcnt76),
    .pcnt77     (pcnt77),
    .pcnt78     (pcnt78),
    .pcnt79     (pcnt79),
    .pcnt80     (pcnt80),
    .pcnt81     (pcnt81),
    .pcnt82     (pcnt82),
    .pcnt83     (pcnt83),
    .pcnt84     (pcnt84),
    .pcnt85     (pcnt85),
    .pcnt86     (pcnt86),
    .pcnt87     (pcnt87),
    .pcnt88     (pcnt88),
    .pcnt89     (pcnt89),
    .pcnt90     (pcnt90),
    .pcnt91     (pcnt91),
    .pcnt92     (pcnt92),
    .pcnt93     (pcnt93),
    .pcnt94     (pcnt94),
    .pcnt95     (pcnt95),
    .pcnt96     (pcnt96),
    .pcnt97     (pcnt97),
    .pcnt98     (pcnt98),
    .pcnt99     (pcnt99),
    .pcnt100    (pcnt100),
    .pcnt101    (pcnt101),
    .pcnt102    (pcnt102),
    .pcnt103    (pcnt103),
    .pcnt104    (pcnt104),
    .pcnt105    (pcnt105),
    .pcnt106    (pcnt106),
    .pcnt107    (pcnt107),
    .pcnt108    (pcnt108),
    .pcnt109    (pcnt109),
    .pcnt110    (pcnt110),
    .pcnt111    (pcnt111),
    .pcnt112    (pcnt112),
    .pcnt113    (pcnt113),
    .pcnt114    (pcnt114),
    .pcnt115    (pcnt115),
    .pcnt116    (pcnt116),
    .pcnt117    (pcnt117),
    .pcnt118    (pcnt118),
    .pcnt119    (pcnt119),
    .pcnt120    (pcnt120),
    .pcnt121    (pcnt121),
    .pcnt122    (pcnt122),
    .pcnt123    (pcnt123),
    .pcnt124    (pcnt124),
    .pcnt125    (pcnt125),
    .pcnt126    (pcnt126),
    .pcnt127    (pcnt127)
);
popcnt_128 pop128_i2
(
    .bitmask    (bitmask[255:128]),
    .pcnt0      (pcnt0_tmp),
    .pcnt1      (pcnt1_tmp),
    .pcnt2      (pcnt2_tmp),
    .pcnt3      (pcnt3_tmp),
    .pcnt4      (pcnt4_tmp),
    .pcnt5      (pcnt5_tmp),
    .pcnt6      (pcnt6_tmp),
    .pcnt7      (pcnt7_tmp),
    .pcnt8      (pcnt8_tmp),
    .pcnt9      (pcnt9_tmp),
    .pcnt10     (pcnt10_tmp),
    .pcnt11     (pcnt11_tmp),
    .pcnt12     (pcnt12_tmp),
    .pcnt13     (pcnt13_tmp),
    .pcnt14     (pcnt14_tmp),
    .pcnt15     (pcnt15_tmp),
    .pcnt16     (pcnt16_tmp),
    .pcnt17     (pcnt17_tmp),
    .pcnt18     (pcnt18_tmp),
    .pcnt19     (pcnt19_tmp),
    .pcnt20     (pcnt20_tmp),
    .pcnt21     (pcnt21_tmp),
    .pcnt22     (pcnt22_tmp),
    .pcnt23     (pcnt23_tmp),
    .pcnt24     (pcnt24_tmp),
    .pcnt25     (pcnt25_tmp),
    .pcnt26     (pcnt26_tmp),
    .pcnt27     (pcnt27_tmp),
    .pcnt28     (pcnt28_tmp),
    .pcnt29     (pcnt29_tmp),
    .pcnt30     (pcnt30_tmp),
    .pcnt31     (pcnt31_tmp),
    .pcnt32     (pcnt32_tmp),
    .pcnt33     (pcnt33_tmp),
    .pcnt34     (pcnt34_tmp),
    .pcnt35     (pcnt35_tmp),
    .pcnt36     (pcnt36_tmp),
    .pcnt37     (pcnt37_tmp),
    .pcnt38     (pcnt38_tmp),
    .pcnt39     (pcnt39_tmp),
    .pcnt40     (pcnt40_tmp),
    .pcnt41     (pcnt41_tmp),
    .pcnt42     (pcnt42_tmp),
    .pcnt43     (pcnt43_tmp),
    .pcnt44     (pcnt44_tmp),
    .pcnt45     (pcnt45_tmp),
    .pcnt46     (pcnt46_tmp),
    .pcnt47     (pcnt47_tmp),
    .pcnt48     (pcnt48_tmp),
    .pcnt49     (pcnt49_tmp),
    .pcnt50     (pcnt50_tmp),
    .pcnt51     (pcnt51_tmp),
    .pcnt52     (pcnt52_tmp),
    .pcnt53     (pcnt53_tmp),
    .pcnt54     (pcnt54_tmp),
    .pcnt55     (pcnt55_tmp),
    .pcnt56     (pcnt56_tmp),
    .pcnt57     (pcnt57_tmp),
    .pcnt58     (pcnt58_tmp),
    .pcnt59     (pcnt59_tmp),
    .pcnt60     (pcnt60_tmp),
    .pcnt61     (pcnt61_tmp),
    .pcnt62     (pcnt62_tmp),
    .pcnt63     (pcnt63_tmp),
    .pcnt64     (pcnt64_tmp),
    .pcnt65     (pcnt65_tmp),
    .pcnt66     (pcnt66_tmp),
    .pcnt67     (pcnt67_tmp),
    .pcnt68     (pcnt68_tmp),
    .pcnt69     (pcnt69_tmp),
    .pcnt70     (pcnt70_tmp),
    .pcnt71     (pcnt71_tmp),
    .pcnt72     (pcnt72_tmp),
    .pcnt73     (pcnt73_tmp),
    .pcnt74     (pcnt74_tmp),
    .pcnt75     (pcnt75_tmp),
    .pcnt76     (pcnt76_tmp),
    .pcnt77     (pcnt77_tmp),
    .pcnt78     (pcnt78_tmp),
    .pcnt79     (pcnt79_tmp),
    .pcnt80     (pcnt80_tmp),
    .pcnt81     (pcnt81_tmp),
    .pcnt82     (pcnt82_tmp),
    .pcnt83     (pcnt83_tmp),
    .pcnt84     (pcnt84_tmp),
    .pcnt85     (pcnt85_tmp),
    .pcnt86     (pcnt86_tmp),
    .pcnt87     (pcnt87_tmp),
    .pcnt88     (pcnt88_tmp),
    .pcnt89     (pcnt89_tmp),
    .pcnt90     (pcnt90_tmp),
    .pcnt91     (pcnt91_tmp),
    .pcnt92     (pcnt92_tmp),
    .pcnt93     (pcnt93_tmp),
    .pcnt94     (pcnt94_tmp),
    .pcnt95     (pcnt95_tmp),
    .pcnt96     (pcnt96_tmp),
    .pcnt97     (pcnt97_tmp),
    .pcnt98     (pcnt98_tmp),
    .pcnt99     (pcnt99_tmp),
    .pcnt100    (pcnt100_tmp),
    .pcnt101    (pcnt101_tmp),
    .pcnt102    (pcnt102_tmp),
    .pcnt103    (pcnt103_tmp),
    .pcnt104    (pcnt104_tmp),
    .pcnt105    (pcnt105_tmp),
    .pcnt106    (pcnt106_tmp),
    .pcnt107    (pcnt107_tmp),
    .pcnt108    (pcnt108_tmp),
    .pcnt109    (pcnt109_tmp),
    .pcnt110    (pcnt110_tmp),
    .pcnt111    (pcnt111_tmp),
    .pcnt112    (pcnt112_tmp),
    .pcnt113    (pcnt113_tmp),
    .pcnt114    (pcnt114_tmp),
    .pcnt115    (pcnt115_tmp),
    .pcnt116    (pcnt116_tmp),
    .pcnt117    (pcnt117_tmp),
    .pcnt118    (pcnt118_tmp),
    .pcnt119    (pcnt119_tmp),
    .pcnt120    (pcnt120_tmp),
    .pcnt121    (pcnt121_tmp),
    .pcnt122    (pcnt122_tmp),
    .pcnt123    (pcnt123_tmp),
    .pcnt124    (pcnt124_tmp),
    .pcnt125    (pcnt125_tmp),
    .pcnt126    (pcnt126_tmp),
    .pcnt127    (pcnt127_tmp)
);
assign pcnt128 = pcnt0_tmp ^ pcnt127[0];
assign pcnt129 = pcnt1_tmp + pcnt127[1:0];
assign pcnt130 = pcnt2_tmp ^ pcnt127[0];
assign pcnt131 = pcnt3_tmp + pcnt127[2:0];
assign pcnt132 = pcnt4_tmp ^ pcnt127[0];
assign pcnt133 = pcnt5_tmp + pcnt127[1:0];
assign pcnt134 = pcnt6_tmp ^ pcnt127[0];
assign pcnt135 = pcnt7_tmp + pcnt127[3:0];
assign pcnt136 = pcnt8_tmp ^ pcnt127[0];
assign pcnt137 = pcnt9_tmp + pcnt127[1:0];
assign pcnt138 = pcnt10_tmp ^ pcnt127[0];
assign pcnt139 = pcnt11_tmp + pcnt127[2:0];
assign pcnt140 = pcnt12_tmp ^ pcnt127[0];
assign pcnt141 = pcnt13_tmp + pcnt127[1:0];
assign pcnt142 = pcnt14_tmp ^ pcnt127[0];
assign pcnt143 = pcnt15_tmp + pcnt127[4:0];
assign pcnt144 = pcnt16_tmp ^ pcnt127[0];
assign pcnt145 = pcnt17_tmp + pcnt127[1:0];
assign pcnt146 = pcnt18_tmp ^ pcnt127[0];
assign pcnt147 = pcnt19_tmp + pcnt127[2:0];
assign pcnt148 = pcnt20_tmp ^ pcnt127[0];
assign pcnt149 = pcnt21_tmp + pcnt127[1:0];
assign pcnt150 = pcnt22_tmp ^ pcnt127[0];
assign pcnt151 = pcnt23_tmp + pcnt127[3:0];
assign pcnt152 = pcnt24_tmp ^ pcnt127[0];
assign pcnt153 = pcnt25_tmp + pcnt127[1:0];
assign pcnt154 = pcnt26_tmp ^ pcnt127[0];
assign pcnt155 = pcnt27_tmp + pcnt127[2:0];
assign pcnt156 = pcnt28_tmp ^ pcnt127[0];
assign pcnt157 = pcnt29_tmp + pcnt127[1:0];
assign pcnt158 = pcnt30_tmp ^ pcnt127[0];
assign pcnt159 = pcnt31_tmp + pcnt127[5:0];
assign pcnt160 = pcnt32_tmp ^ pcnt127[0];
assign pcnt161 = pcnt33_tmp + pcnt127[1:0];
assign pcnt162 = pcnt34_tmp ^ pcnt127[0];
assign pcnt163 = pcnt35_tmp + pcnt127[2:0];
assign pcnt164 = pcnt36_tmp ^ pcnt127[0];
assign pcnt165 = pcnt37_tmp + pcnt127[1:0];
assign pcnt166 = pcnt38_tmp ^ pcnt127[0];
assign pcnt167 = pcnt39_tmp + pcnt127[3:0];
assign pcnt168 = pcnt40_tmp ^ pcnt127[0];
assign pcnt169 = pcnt41_tmp + pcnt127[1:0];
assign pcnt170 = pcnt42_tmp ^ pcnt127[0];
assign pcnt171 = pcnt43_tmp + pcnt127[2:0];
assign pcnt172 = pcnt44_tmp ^ pcnt127[0];
assign pcnt173 = pcnt45_tmp + pcnt127[1:0];
assign pcnt174 = pcnt46_tmp ^ pcnt127[0];
assign pcnt175 = pcnt47_tmp + pcnt127[4:0];
assign pcnt176 = pcnt48_tmp ^ pcnt127[0];
assign pcnt177 = pcnt49_tmp + pcnt127[1:0];
assign pcnt178 = pcnt50_tmp ^ pcnt127[0];
assign pcnt179 = pcnt51_tmp + pcnt127[2:0];
assign pcnt180 = pcnt52_tmp ^ pcnt127[0];
assign pcnt181 = pcnt53_tmp + pcnt127[1:0];
assign pcnt182 = pcnt54_tmp ^ pcnt127[0];
assign pcnt183 = pcnt55_tmp + pcnt127[3:0];
assign pcnt184 = pcnt56_tmp ^ pcnt127[0];
assign pcnt185 = pcnt57_tmp + pcnt127[1:0];
assign pcnt186 = pcnt58_tmp ^ pcnt127[0];
assign pcnt187 = pcnt59_tmp + pcnt127[2:0];
assign pcnt188 = pcnt60_tmp ^ pcnt127[0];
assign pcnt189 = pcnt61_tmp + pcnt127[1:0];
assign pcnt190 = pcnt62_tmp ^ pcnt127[0];
assign pcnt191 = pcnt63_tmp + pcnt127[6:0];
assign pcnt192 = pcnt64_tmp ^ pcnt127[0];
assign pcnt193 = pcnt65_tmp + pcnt127[1:0];
assign pcnt194 = pcnt66_tmp ^ pcnt127[0];
assign pcnt195 = pcnt67_tmp + pcnt127[2:0];
assign pcnt196 = pcnt68_tmp ^ pcnt127[0];
assign pcnt197 = pcnt69_tmp + pcnt127[1:0];
assign pcnt198 = pcnt70_tmp ^ pcnt127[0];
assign pcnt199 = pcnt71_tmp + pcnt127[3:0];
assign pcnt200 = pcnt72_tmp ^ pcnt127[0];
assign pcnt201 = pcnt73_tmp + pcnt127[1:0];
assign pcnt202 = pcnt74_tmp ^ pcnt127[0];
assign pcnt203 = pcnt75_tmp + pcnt127[2:0];
assign pcnt204 = pcnt76_tmp ^ pcnt127[0];
assign pcnt205 = pcnt77_tmp + pcnt127[1:0];
assign pcnt206 = pcnt78_tmp ^ pcnt127[0];
assign pcnt207 = pcnt79_tmp + pcnt127[4:0];
assign pcnt208 = pcnt80_tmp ^ pcnt127[0];
assign pcnt209 = pcnt81_tmp + pcnt127[1:0];
assign pcnt210 = pcnt82_tmp ^ pcnt127[0];
assign pcnt211 = pcnt83_tmp + pcnt127[2:0];
assign pcnt212 = pcnt84_tmp ^ pcnt127[0];
assign pcnt213 = pcnt85_tmp + pcnt127[1:0];
assign pcnt214 = pcnt86_tmp ^ pcnt127[0];
assign pcnt215 = pcnt87_tmp + pcnt127[3:0];
assign pcnt216 = pcnt88_tmp ^ pcnt127[0];
assign pcnt217 = pcnt89_tmp + pcnt127[1:0];
assign pcnt218 = pcnt90_tmp ^ pcnt127[0];
assign pcnt219 = pcnt91_tmp + pcnt127[2:0];
assign pcnt220 = pcnt92_tmp ^ pcnt127[0];
assign pcnt221 = pcnt93_tmp + pcnt127[1:0];
assign pcnt222 = pcnt94_tmp ^ pcnt127[0];
assign pcnt223 = pcnt95_tmp + pcnt127[5:0];
assign pcnt224 = pcnt96_tmp ^ pcnt127[0];
assign pcnt225 = pcnt97_tmp + pcnt127[1:0];
assign pcnt226 = pcnt98_tmp ^ pcnt127[0];
assign pcnt227 = pcnt99_tmp + pcnt127[2:0];
assign pcnt228 = pcnt100_tmp ^ pcnt127[0];
assign pcnt229 = pcnt101_tmp + pcnt127[1:0];
assign pcnt230 = pcnt102_tmp ^ pcnt127[0];
assign pcnt231 = pcnt103_tmp + pcnt127[3:0];
assign pcnt232 = pcnt104_tmp ^ pcnt127[0];
assign pcnt233 = pcnt105_tmp + pcnt127[1:0];
assign pcnt234 = pcnt106_tmp ^ pcnt127[0];
assign pcnt235 = pcnt107_tmp + pcnt127[2:0];
assign pcnt236 = pcnt108_tmp ^ pcnt127[0];
assign pcnt237 = pcnt109_tmp + pcnt127[1:0];
assign pcnt238 = pcnt110_tmp ^ pcnt127[0];
assign pcnt239 = pcnt111_tmp + pcnt127[4:0];
assign pcnt240 = pcnt112_tmp ^ pcnt127[0];
assign pcnt241 = pcnt113_tmp + pcnt127[1:0];
assign pcnt242 = pcnt114_tmp ^ pcnt127[0];
assign pcnt243 = pcnt115_tmp + pcnt127[2:0];
assign pcnt244 = pcnt116_tmp ^ pcnt127[0];
assign pcnt245 = pcnt117_tmp + pcnt127[1:0];
assign pcnt246 = pcnt118_tmp ^ pcnt127[0];
assign pcnt247 = pcnt119_tmp + pcnt127[3:0];
assign pcnt248 = pcnt120_tmp ^ pcnt127[0];
assign pcnt249 = pcnt121_tmp + pcnt127[1:0];
assign pcnt250 = pcnt122_tmp ^ pcnt127[0];
assign pcnt251 = pcnt123_tmp + pcnt127[2:0];
assign pcnt252 = pcnt124_tmp ^ pcnt127[0];
assign pcnt253 = pcnt125_tmp + pcnt127[1:0];
assign pcnt254 = pcnt126_tmp ^ pcnt127[0];
//assign pcnt255 = pcnt127_tmp + pcnt127;

endmodule
