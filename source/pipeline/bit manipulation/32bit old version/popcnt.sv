// population count used in bitmask decoder
// 2 adder recuisive arch
// Author: Guozhu Xin
// Date:   2018/5/21

module popcnt
(
    input   logic [31:0]  bitmask,
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
    output  logic         pcnt30
);

// stage 1
logic   [15:0]  [1:0] sum1;
always_comb begin
    for (int i = 0; i < 16; i = i + 1) begin
        sum1[i] = bitmask[2*i] + bitmask[2*i + 1];
    end
end

// stage 2
logic   [7:0]  [2:0] sum2;
always_comb begin
    for (int i = 0; i < 8; i = i + 1) begin
        sum2[i] = sum1[2*i] + sum1[2*i + 1];
    end
end

// stage 3
logic   [3:0]  [3:0] sum3;
always_comb begin
    for (int i = 0; i < 4; i = i + 1) begin
        sum3[i] = sum2[2*i] + sum2[2*i + 1];
    end
end


// stage 4
logic   [1:0]  [4:0] sum4;
always_comb begin
    for (int i = 0; i < 2; i = i + 1) begin
        sum4[i] = sum3[2*i] + sum3[2*i + 1];
    end
end


//output
assign pcnt0  = bitmask[0];
assign pcnt1  = sum1[0];
assign pcnt2  = sum1[0][0] ^ bitmask[2];
assign pcnt3  = sum2[0];
assign pcnt4  = sum2[0][0] ^ bitmask[4];
assign pcnt5  = sum2[0][1:0] + sum1[2];
assign pcnt6  = pcnt5[0] ^ bitmask[6];
assign pcnt7  = sum3[0];
assign pcnt8  = sum3[0][0] ^ bitmask[8];
assign pcnt9  = sum3[0][1:0] + sum1[4];
assign pcnt10 = pcnt9[0] ^ bitmask[10];
assign pcnt11 = sum3[0][2:0] + sum2[2];
assign pcnt12 = pcnt11[0] ^ bitmask[12];
assign pcnt13 = pcnt11[1:0] + sum1[6];
assign pcnt14 = pcnt13[0] ^ bitmask[14];
assign pcnt15 = sum4[0];
assign pcnt16 = sum4[0][0] ^ bitmask[16];
assign pcnt17 = sum4[0][1:0] + sum1[8];
assign pcnt18 = pcnt17[0] ^ bitmask[18];
assign pcnt19 = sum4[0][2:0] + sum2[4];
assign pcnt20 = pcnt19[0] ^ bitmask[20];
assign pcnt21 = pcnt19[1:0] + sum1[10];
assign pcnt22 = pcnt21[0] ^ bitmask[22];
assign pcnt23 = sum4[0][3:0] + sum3[2];
assign pcnt24 = pcnt23[0] ^ bitmask[24];
assign pcnt25 = pcnt23[1:0] + sum1[12];
assign pcnt26 = pcnt25[0] ^ bitmask[26];
assign pcnt27 = pcnt23[2:0] + sum2[6];
assign pcnt28 = pcnt27[0] ^ bitmask[28];
assign pcnt29 = pcnt27[1:0] + sum1[14];
assign pcnt30 = sum4[0][0] ^ sum4[1][0] ^ bitmask[30];
//assign pcnt30 = pcnt29[0] ^ bitmask[30];

endmodule
