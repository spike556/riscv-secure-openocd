
module mask_decoder
(
    input   logic [31:0]  bitmask,
    output  logic [15:0]  ibfly_cfg0,              // stage1
    output  logic [15:0]  ibfly_cfg1,
    output  logic [15:0]  ibfly_cfg2,
    output  logic [15:0]  ibfly_cfg3,
    output  logic [15:0]  ibfly_cfg4
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
popcnt popcnt_i
(
    .bitmask      (bitmask),
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
    .pcnt30       (pcnt30)
);

lrotc lrotc_i
(
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
    .ibfly_cfg0   (ibfly_cfg0),              // stage1
    .ibfly_cfg1   (ibfly_cfg1),
    .ibfly_cfg2   (ibfly_cfg2),
    .ibfly_cfg3   (ibfly_cfg3),
    .ibfly_cfg4   (ibfly_cfg4)
);

endmodule
