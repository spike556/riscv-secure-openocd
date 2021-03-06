module mask_decoder
(
    input   logic [255:0]  bitmask,
    output  logic [127:0]  ibfly_cfg0,              // stage1
    output  logic [127:0]  ibfly_cfg1,
    output  logic [127:0]  ibfly_cfg2,
    output  logic [127:0]  ibfly_cfg3,
    output  logic [127:0]  ibfly_cfg4,
    output  logic [127:0]  ibfly_cfg5,
    output  logic [127:0]  ibfly_cfg6,
    output  logic [127:0]  ibfly_cfg7
);

logic         pcnt0;
logic [1:0]   pcnt1;
logic         pcnt2;
logic [2:0]   pcnt3;
logic         pcnt4;
logic [1:0]   pcnt5;
logic         pcnt6;
logic [3:0]   pcnt7;
logic         pcnt8;
logic [1:0]   pcnt9;
logic         pcnt10;
logic [2:0]   pcnt11;
logic         pcnt12;
logic [1:0]   pcnt13;
logic         pcnt14;
logic [4:0]   pcnt15;
logic         pcnt16;
logic [1:0]   pcnt17;
logic         pcnt18;
logic [2:0]   pcnt19;
logic         pcnt20;
logic [1:0]   pcnt21;
logic         pcnt22;
logic [3:0]   pcnt23;
logic         pcnt24;
logic [1:0]   pcnt25;
logic         pcnt26;
logic [2:0]   pcnt27;
logic         pcnt28;
logic [1:0]   pcnt29;
logic         pcnt30;
logic [5:0]   pcnt31;
logic         pcnt32;
logic [1:0]   pcnt33;
logic         pcnt34;
logic [2:0]   pcnt35;
logic         pcnt36;
logic [1:0]   pcnt37;
logic         pcnt38;
logic [3:0]   pcnt39;
logic         pcnt40;
logic [1:0]   pcnt41;
logic         pcnt42;
logic [2:0]   pcnt43;
logic         pcnt44;
logic [1:0]   pcnt45;
logic         pcnt46;
logic [4:0]   pcnt47;
logic         pcnt48;
logic [1:0]   pcnt49;
logic         pcnt50;
logic [2:0]   pcnt51;
logic         pcnt52;
logic [1:0]   pcnt53;
logic         pcnt54;
logic [3:0]   pcnt55;
logic         pcnt56;
logic [1:0]   pcnt57;
logic         pcnt58;
logic [2:0]   pcnt59;
logic         pcnt60;
logic [1:0]   pcnt61;
logic         pcnt62;
logic [6:0]   pcnt63;
logic         pcnt64;
logic [1:0]   pcnt65;
logic         pcnt66;
logic [2:0]   pcnt67;
logic         pcnt68;
logic [1:0]   pcnt69;
logic         pcnt70;
logic [3:0]   pcnt71;
logic         pcnt72;
logic [1:0]   pcnt73;
logic         pcnt74;
logic [2:0]   pcnt75;
logic         pcnt76;
logic [1:0]   pcnt77;
logic         pcnt78;
logic [4:0]   pcnt79;
logic         pcnt80;
logic [1:0]   pcnt81;
logic         pcnt82;
logic [2:0]   pcnt83;
logic         pcnt84;
logic [1:0]   pcnt85;
logic         pcnt86;
logic [3:0]   pcnt87;
logic         pcnt88;
logic [1:0]   pcnt89;
logic         pcnt90;
logic [2:0]   pcnt91;
logic         pcnt92;
logic [1:0]   pcnt93;
logic         pcnt94;
logic [5:0]   pcnt95;
logic         pcnt96;
logic [1:0]   pcnt97;
logic         pcnt98;
logic [2:0]   pcnt99;
logic         pcnt100;
logic [1:0]   pcnt101;
logic         pcnt102;
logic [3:0]   pcnt103;
logic         pcnt104;
logic [1:0]   pcnt105;
logic         pcnt106;
logic [2:0]   pcnt107;
logic         pcnt108;
logic [1:0]   pcnt109;
logic         pcnt110;
logic [4:0]   pcnt111;
logic         pcnt112;
logic [1:0]   pcnt113;
logic         pcnt114;
logic [2:0]   pcnt115;
logic         pcnt116;
logic [1:0]   pcnt117;
logic         pcnt118;
logic [3:0]   pcnt119;
logic         pcnt120;
logic [1:0]   pcnt121;
logic         pcnt122;
logic [2:0]   pcnt123;
logic         pcnt124;
logic [1:0]   pcnt125;
logic         pcnt126;
logic [7:0]   pcnt127;
logic         pcnt128;
logic [1:0]   pcnt129;
logic         pcnt130;
logic [2:0]   pcnt131;
logic         pcnt132;
logic [1:0]   pcnt133;
logic         pcnt134;
logic [3:0]   pcnt135;
logic         pcnt136;
logic [1:0]   pcnt137;
logic         pcnt138;
logic [2:0]   pcnt139;
logic         pcnt140;
logic [1:0]   pcnt141;
logic         pcnt142;
logic [4:0]   pcnt143;
logic         pcnt144;
logic [1:0]   pcnt145;
logic         pcnt146;
logic [2:0]   pcnt147;
logic         pcnt148;
logic [1:0]   pcnt149;
logic         pcnt150;
logic [3:0]   pcnt151;
logic         pcnt152;
logic [1:0]   pcnt153;
logic         pcnt154;
logic [2:0]   pcnt155;
logic         pcnt156;
logic [1:0]   pcnt157;
logic         pcnt158;
logic [5:0]   pcnt159;
logic         pcnt160;
logic [1:0]   pcnt161;
logic         pcnt162;
logic [2:0]   pcnt163;
logic         pcnt164;
logic [1:0]   pcnt165;
logic         pcnt166;
logic [3:0]   pcnt167;
logic         pcnt168;
logic [1:0]   pcnt169;
logic         pcnt170;
logic [2:0]   pcnt171;
logic         pcnt172;
logic [1:0]   pcnt173;
logic         pcnt174;
logic [4:0]   pcnt175;
logic         pcnt176;
logic [1:0]   pcnt177;
logic         pcnt178;
logic [2:0]   pcnt179;
logic         pcnt180;
logic [1:0]   pcnt181;
logic         pcnt182;
logic [3:0]   pcnt183;
logic         pcnt184;
logic [1:0]   pcnt185;
logic         pcnt186;
logic [2:0]   pcnt187;
logic         pcnt188;
logic [1:0]   pcnt189;
logic         pcnt190;
logic [6:0]   pcnt191;
logic         pcnt192;
logic [1:0]   pcnt193;
logic         pcnt194;
logic [2:0]   pcnt195;
logic         pcnt196;
logic [1:0]   pcnt197;
logic         pcnt198;
logic [3:0]   pcnt199;
logic         pcnt200;
logic [1:0]   pcnt201;
logic         pcnt202;
logic [2:0]   pcnt203;
logic         pcnt204;
logic [1:0]   pcnt205;
logic         pcnt206;
logic [4:0]   pcnt207;
logic         pcnt208;
logic [1:0]   pcnt209;
logic         pcnt210;
logic [2:0]   pcnt211;
logic         pcnt212;
logic [1:0]   pcnt213;
logic         pcnt214;
logic [3:0]   pcnt215;
logic         pcnt216;
logic [1:0]   pcnt217;
logic         pcnt218;
logic [2:0]   pcnt219;
logic         pcnt220;
logic [1:0]   pcnt221;
logic         pcnt222;
logic [5:0]   pcnt223;
logic         pcnt224;
logic [1:0]   pcnt225;
logic         pcnt226;
logic [2:0]   pcnt227;
logic         pcnt228;
logic [1:0]   pcnt229;
logic         pcnt230;
logic [3:0]   pcnt231;
logic         pcnt232;
logic [1:0]   pcnt233;
logic         pcnt234;
logic [2:0]   pcnt235;
logic         pcnt236;
logic [1:0]   pcnt237;
logic         pcnt238;
logic [4:0]   pcnt239;
logic         pcnt240;
logic [1:0]   pcnt241;
logic         pcnt242;
logic [2:0]   pcnt243;
logic         pcnt244;
logic [1:0]   pcnt245;
logic         pcnt246;
logic [3:0]   pcnt247;
logic         pcnt248;
logic [1:0]   pcnt249;
logic         pcnt250;
logic [2:0]   pcnt251;
logic         pcnt252;
logic [1:0]   pcnt253;
logic         pcnt254;

popcnt_256 pop256_i
(
    .*
);

lrotc lrotc_i
(
    .*
);

endmodule
