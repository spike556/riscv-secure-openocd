// bit manipulation operation
// specificly support GROUP operation
// Author: Guozhu Xin
// Date:   2018/5/21
module bitu
(
    input   logic [31:0] data_in,
    input   logic [31:0] bitmask,
    output  logic [31:0] data_out
);

// GRPR
logic [31:0]  grpr_data;
logic [15:0]  ibfly_cfg0_grpr;
logic [15:0]  ibfly_cfg1_grpr;
logic [15:0]  ibfly_cfg2_grpr;
logic [15:0]  ibfly_cfg3_grpr;
logic [15:0]  ibfly_cfg4_grpr;
logic [31:0]  grpr_data_out;

assign grpr_data = data_in  & bitmask;
mask_decoder mask_decoder_i
(
    .bitmask            (bitmask),
    .ibfly_cfg0         (ibfly_cfg0_grpr),
    .ibfly_cfg1         (ibfly_cfg1_grpr),
    .ibfly_cfg2         (ibfly_cfg2_grpr),
    .ibfly_cfg3         (ibfly_cfg3_grpr),
    .ibfly_cfg4         (ibfly_cfg4_grpr)
);

ibutterfly_net_32 ibutterfly_net_32_i1
(
    .cfg0           (ibfly_cfg0_grpr),
    .cfg1           (ibfly_cfg1_grpr),
    .cfg2           (ibfly_cfg2_grpr),
    .cfg3           (ibfly_cfg3_grpr),
    .cfg4           (ibfly_cfg4_grpr),
    .data_in        (grpr_data),
    .data_out       (grpr_data_out)
);

//GRPL
logic [31:0]  grpl_data_mirror;
logic [31:0]  bitmask_mirror_inv;
logic [15:0]  ibfly_cfg0_grpl;
logic [15:0]  ibfly_cfg1_grpl;
logic [15:0]  ibfly_cfg2_grpl;
logic [15:0]  ibfly_cfg3_grpl;
logic [15:0]  ibfly_cfg4_grpl;
logic [31:0]  grpl_data_out_mirror;
logic [31:0]  grpl_data_out;

always_comb begin
    for(int i = 0; i < 32; i = i + 1) begin
        bitmask_mirror_inv[i] = ~bitmask[31-i];
    end
end
always_comb begin
    for(int i = 0; i < 32; i = i + 1) begin
        grpl_data_mirror[i] = data_in[31-i] & bitmask_mirror_inv[i];
    end
end

mask_decoder mask_decoder_mirror_i
(
    .bitmask            (bitmask_mirror_inv),
    .ibfly_cfg0         (ibfly_cfg0_grpl),
    .ibfly_cfg1         (ibfly_cfg1_grpl),
    .ibfly_cfg2         (ibfly_cfg2_grpl),
    .ibfly_cfg3         (ibfly_cfg3_grpl),
    .ibfly_cfg4         (ibfly_cfg4_grpl)
);

ibutterfly_net_32 ibutterfly_net_32_i2
(
    .cfg0           (ibfly_cfg0_grpl),
    .cfg1           (ibfly_cfg1_grpl),
    .cfg2           (ibfly_cfg2_grpl),
    .cfg3           (ibfly_cfg3_grpl),
    .cfg4           (ibfly_cfg4_grpl),
    .data_in        (grpl_data_mirror),
    .data_out       (grpl_data_out_mirror)
);

always_comb begin
    for(int i = 0; i < 32; i = i + 1) begin
        grpl_data_out[i] = grpl_data_out_mirror[31-i];
    end
end

assign data_out = grpl_data_out | grpr_data_out;

endmodule
