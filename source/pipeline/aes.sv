`include "scr1_riscv_isa_decoding.svh"

module aes
(
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    //  VEXU  -> AES Interface
    input  logic                                vexu2aes_req,            // vexu request
    input  type_scr1_vcrypt_func_e              vexu2aes_func,
    input  type_scr1_vcrypt_length_e            vexu2aes_length,
    output logic                                aes2vexu_rdy,
    input  type_scr1_vrf_e_v [3:0]              aes_op1,                // encrypt:msg  decrypt:cipher
    input  type_scr1_vrf_e_v [`LANE-1:0]        aes_op2,                // key
    output type_scr1_vrf_e_v [3:0]              aes_res,
    output logic [7:0]                          aes_wreq
);

// -------------------------aes inline function----------------------------------
function logic [31:0]  RotWord  (
    input logic [31:0]  a
);
    logic [31:0]  out;
begin
    out = {a[23:0], a[31:24]};
    return out;
end
endfunction : RotWord

function logic [127:0] ShiftRows  (
    input   logic [127:0]  in
);
    logic         [31:0]  a;
    logic         [31:0]  b;
    logic         [31:0]  c;
    logic         [31:0]  d;
    logic         [31:0]  new_a;
    logic         [31:0]  new_b;
    logic         [31:0]  new_c;
    logic         [31:0]  new_d;
    logic         [127:0] out;
begin
    a     = in[127:96];
    b     = in[95:64];
    c     = in[63:32];
    d     = in[31:0];
    new_a = {a[31:24], b[23:16], c[15:8], d[7:0]};
    new_b = {b[31:24], c[23:16], d[15:8], a[7:0]};
    new_c = {c[31:24], d[23:16], a[15:8], b[7:0]};
    new_d = {d[31:24], a[23:16], b[15:8], c[7:0]};
    out = {new_a, new_b, new_c, new_d};
    return out;
end
endfunction : ShiftRows

function logic [127:0] InvShiftRows  (
    input   logic [127:0]  in
);
    logic         [31:0]  a;
    logic         [31:0]  b;
    logic         [31:0]  c;
    logic         [31:0]  d;
    logic         [31:0]  new_a;
    logic         [31:0]  new_b;
    logic         [31:0]  new_c;
    logic         [31:0]  new_d;
    logic         [127:0] out;
begin
    a     = in[127:96];
    b     = in[95:64];
    c     = in[63:32];
    d     = in[31:0];
    new_a = {a[31:24], d[23:16], c[15:8], b[7:0]};
    new_b = {b[31:24], a[23:16], d[15:8], c[7:0]};
    new_c = {c[31:24], b[23:16], a[15:8], d[7:0]};
    new_d = {d[31:24], c[23:16], b[15:8], a[7:0]};
    out = {new_a, new_b, new_c, new_d};
    return out;
end
endfunction : InvShiftRows

function logic [127 : 0] AddRoundKey(input [127 : 0] data, input [127 : 0] rkey);
    logic [127 : 0] out;
begin
    out = data ^ rkey;
    return out;
end
endfunction : AddRoundKey

function logic [7:0]  mul2 (
    input   logic [7:0]  a
);
    logic         [7:0] out;
begin
    out = {a[6 : 0], 1'b0} ^ (8'h1b & {8{a[7]}});
    return out;
end
endfunction : mul2

function logic [7:0]  mul3 (
    input   logic [7:0]  a
);
    logic         [7:0] out;
begin
    out = mul2(a)  ^ a;
    return out;
end
endfunction : mul3

function logic [7 : 0] mul4(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul2(mul2(op));
    return out;
end
endfunction : mul4

function logic [7 : 0] mul8(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul2(mul4(op));
    return out;
end
endfunction : mul8

function logic [7 : 0] mul9(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul8(op)  ^ op;
    return out;
end
endfunction : mul9

function logic [7 : 0] mul11(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul8(op)  ^ mul3(op);
    return out;
end
endfunction : mul11

function logic [7 : 0] mul13(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul8(op)  ^ mul4(op)  ^ op;
    return out;
end
endfunction : mul13

function logic [7 : 0] mul14(input [7 : 0] op);
    logic [7 : 0] out;
begin
    out = mul8(op)  ^ mul4(op)  ^ mul2(op);
    return out;
end
endfunction : mul14

function logic [31:0]  MixColumn (
    input   logic [31:0]  a
);
    logic         [31:0] out;
begin
    out = {mul2(a[31:24]) ^ mul3(a[23:16]) ^ a[15:8]  ^ a[7:0],
           a[31:24] ^ mul2(a[23:16]) ^ mul3(a[15:8])  ^ a[7:0],
           a[31:24]  ^ a[23:16] ^ mul2(a[15:8])  ^ mul3(a[7:0]),
           mul3(a[31:24])  ^ a[23:16] ^ a[15:8]  ^ mul2(a[7:0])};
    return out;
end
endfunction : MixColumn

function logic [127:0]  MixColumns (
    input   logic [127:0]  a
);
    logic         [127:0] out;
    logic         [31:0]  a0;
    logic         [31:0]  a1;
    logic         [31:0]  a2;
    logic         [31:0]  a3;
    logic         [31:0]  out0;
    logic         [31:0]  out1;
    logic         [31:0]  out2;
    logic         [31:0]  out3;
begin
    a0  = a[127:96];
    a1  = a[95:64];
    a2  = a[63:32];
    a3  = a[31:0];
    out0 = MixColumn(a0);
    out1 = MixColumn(a1);
    out2 = MixColumn(a2);
    out3 = MixColumn(a3);
    out  = {out0, out1, out2, out3};
    return out;
end
endfunction : MixColumns

function logic [31:0]  InvMixColumn (
    input   logic [31:0]  a
);
    logic         [31:0] out;
begin
    out = {mul14(a[31:24]) ^ mul11(a[23:16]) ^ mul13(a[15:8])  ^ mul9(a[7:0]),
           mul9(a[31:24]) ^ mul14(a[23:16]) ^ mul11(a[15:8])  ^ mul13(a[7:0]),
           mul13(a[31:24]) ^ mul9(a[23:16]) ^ mul14(a[15:8])  ^ mul11(a[7:0]),
           mul11(a[31:24]) ^ mul13(a[23:16]) ^ mul9(a[15:8])  ^ mul14(a[7:0])};
    return out;
end
endfunction : InvMixColumn

function logic [127:0]  InvMixColumns (
    input   logic [127:0]  a
);
    logic         [127:0] out;
    logic         [31:0]  a0;
    logic         [31:0]  a1;
    logic         [31:0]  a2;
    logic         [31:0]  a3;
    logic         [31:0]  out0;
    logic         [31:0]  out1;
    logic         [31:0]  out2;
    logic         [31:0]  out3;
begin
    a0  = a[127:96];
    a1  = a[95:64];
    a2  = a[63:32];
    a3  = a[31:0];
    out0 = InvMixColumn(a0);
    out1 = InvMixColumn(a1);
    out2 = InvMixColumn(a2);
    out3 = InvMixColumn(a3);
    out  = {out0, out1, out2, out3};
    return out;
end
endfunction : InvMixColumns
//---------------------------------------------------------------------------------
//----------------------------AES main logic---------------------------------------
//----------------------------AES sbox--------------------------------------------
logic [127:0]                       aes2sbox;
logic [127:0]                       aes2invsbox;
logic [127:0]                       sbox2aes;
logic [127:0]                       invsbox2aes;

aes_sbox i_aes_sbox(
    .addr                 (aes2sbox),
    .data                 (sbox2aes)      // read data
);

aes_inv_sbox i_aes_inv_sbox(
    .addr                 (aes2invsbox),
    .data                 (invsbox2aes)     // read data
);

//-------------------------------------------------------------------------
logic           AES_key_finish;
logic           AES_enc_finish;
logic           AES_dec_finish;

assign aes2vexu_rdy = AES_key_finish | AES_enc_finish | AES_dec_finish;

// -------------------------key expansion-------------------------------------------
localparam bit [7:0] RCON[12] = '{
    8'h8d, 8'h01, 8'h02, 8'h04, 8'h08, 8'h10,
    8'h20, 8'h40, 8'h80, 8'h1b, 8'h36, 8'h6c
};

logic [3:0]   NUM_KEY_EXP_ROUNDS;
always_comb begin
    case (vexu2aes_length)
        SCR1_VCRYPT_256BIT  : NUM_KEY_EXP_ROUNDS = 4'he;
        SCR1_VCRYPT_128BIT  : NUM_KEY_EXP_ROUNDS = 4'ha;
    endcase
end

logic       [3:0]   aes_key_cnt;
logic       [3:0]   aes_key_cnt_new;
logic       [31:0]  rcon_val;
assign     rcon_val  = {RCON[aes_key_cnt], 24'h0};
assign     AES_key_finish = (aes_key_cnt  ==  NUM_KEY_EXP_ROUNDS);
assign     aes_key_cnt_new = (aes_key_cnt ==  NUM_KEY_EXP_ROUNDS)  ? 4'h0  : aes_key_cnt + 4'b1;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_key_cnt  <=  '0;
    end else begin
        if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_KEY_EXPAN) begin
            aes_key_cnt <=  aes_key_cnt_new;
        end
    end
end

logic  [12:0] [127 : 0] key_mem;
logic         [127 : 0] key_mem_new;
logic  [1:0]  [127 : 0] key256_flat;
logic  [14:0] [127 : 0] key_mem_unified;

logic  [31 : 0] w0, w1, w2, w3, w4, w5, w6, w7;
logic  [31 : 0] k0, k1, k2, k3;
logic  [31 : 0] tw, trw;
logic  [127 : 0] prev_key0;
logic  [127 : 0] prev_key1;

logic [3:0] aes_key_cnt_prev1;
logic [3:0] aes_key_cnt_prev0;
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_key_cnt_prev1 <=  '0;
        aes_key_cnt_prev0 <=  '0;
    end else begin
        aes_key_cnt_prev1 <=  aes_key_cnt;
        aes_key_cnt_prev0 <=  aes_key_cnt_prev1;
    end
end

assign prev_key0      = key_mem_unified[aes_key_cnt_prev0];
assign prev_key1      = key_mem_unified[aes_key_cnt_prev1];
assign key256_flat[0] = {aes_op2[0], aes_op2[1], aes_op2[2], aes_op2[3]};
assign key256_flat[1] = {aes_op2[4], aes_op2[5], aes_op2[6], aes_op2[7]};
always_comb begin
    case (vexu2aes_length)
        SCR1_VCRYPT_256BIT  : key_mem_unified = {key_mem, key256_flat};
        SCR1_VCRYPT_128BIT  : key_mem_unified = {128'h0, key_mem, key256_flat[0]};
    endcase
end

always_comb begin
    w0 = prev_key0[127 : 096];
    w1 = prev_key0[095 : 064];
    w2 = prev_key0[063 : 032];
    w3 = prev_key0[031 : 000];

    w4 = prev_key1[127 : 096];
    w5 = prev_key1[095 : 064];
    w6 = prev_key1[063 : 032];
    w7 = prev_key1[031 : 000];
    tw = sbox2aes[31:0];
    trw = RotWord(sbox2aes[31:0]) ^ rcon_val;
    if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_KEY_EXPAN) begin
        case (vexu2aes_length)
            SCR1_VCRYPT_128BIT  : begin
                k0 = w4 ^ trw;
                k1 = w5 ^ w4 ^ trw;
                k2 = w6 ^ w5 ^ w4 ^ trw;
                k3 = w7 ^ w6 ^ w5 ^ w4 ^ trw;
            end
            SCR1_VCRYPT_256BIT  : begin
                if (aes_key_cnt[0] == 0) begin
                    k0 = w0 ^ trw;
                    k1 = w1 ^ w0 ^ trw;
                    k2 = w2 ^ w1 ^ w0 ^ trw;
                    k3 = w3 ^ w2 ^ w1 ^ w0 ^ trw;
                end else begin
                    k0 = w0 ^ tw;
                    k1 = w1 ^ w0 ^ tw;
                    k2 = w2 ^ w1 ^ w0 ^ tw;
                    k3 = w3 ^ w2 ^ w1 ^ w0 ^ tw;
                end
            end
        endcase
    end else begin
        k0 = 32'h0;
        k1 = 32'h0;
        k2 = 32'h0;
        k3 = 32'h0;
    end
end

assign key_mem_new = {k0, k1, k2, k3};

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        key_mem <=  '0;
    end else begin
        case (vexu2aes_length)
            SCR1_VCRYPT_128BIT  : begin
                if (|aes_key_cnt) begin
                    key_mem[aes_key_cnt_prev1]  <=  key_mem_new;
                end
            end
            SCR1_VCRYPT_256BIT  : begin
                if (|aes_key_cnt[3:1]) begin        // equal to aes_key_cnt>1
                    key_mem[aes_key_cnt_prev0]  <=  key_mem_new;
                end
            end
        endcase
    end
end

//-----------------------------AES encryption--------------------------------------------
logic [3:0]   NUM_ENCDEC_ROUNDS;
always_comb begin
    case (vexu2aes_length)
        SCR1_VCRYPT_256BIT  : NUM_ENCDEC_ROUNDS = 14;
        SCR1_VCRYPT_128BIT  : NUM_ENCDEC_ROUNDS = 10;
    endcase
end

logic  [3:0]                    aes_enc_cnt;
logic  [3:0]                    aes_enc_cnt_new;
assign  aes_enc_cnt_new = (aes_enc_cnt ==  NUM_ENCDEC_ROUNDS)  ? 4'h0  : aes_enc_cnt + 4'b1;
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_enc_cnt  <=  '0;
    end else begin
        if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_ENCRYPT) begin
            aes_enc_cnt <= aes_enc_cnt_new;
        end
    end
end

assign  AES_enc_finish = (aes_enc_cnt == NUM_ENCDEC_ROUNDS);

logic [127 : 0]              aes_res_reg0;
logic [127 : 0]              aes_res_new0;
logic [127 : 0]              aes_op1_flat;
logic [127 : 0] shiftrows_block, mixcolumns_block;
logic [127 : 0] addkey_init_block, addkey_main_block, addkey_final_block;

assign  aes_op1_flat = {aes_op1[0], aes_op1[1], aes_op1[2], aes_op1[3]};
always_comb begin
    aes_res_new0 = '0;
    shiftrows_block     = ShiftRows(sbox2aes);
    mixcolumns_block    = MixColumns(shiftrows_block);
    addkey_init_block   = AddRoundKey(aes_op1_flat, key_mem_unified[0]);
    addkey_main_block   = AddRoundKey(mixcolumns_block, key_mem_unified[aes_enc_cnt]);
    addkey_final_block  = AddRoundKey(shiftrows_block, key_mem_unified[aes_enc_cnt]);
    if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_ENCRYPT) begin
        case (aes_enc_cnt)
            4'b0  : aes_res_new0 = addkey_init_block;
            default : begin
                if (aes_enc_cnt != NUM_ENCDEC_ROUNDS) begin
                    aes_res_new0 = addkey_main_block;
                end else begin
                    aes_res_new0 = addkey_final_block;
                end
            end
        endcase
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_res_reg0 <=  '0;
    end else begin
        aes_res_reg0 <=  aes_res_new0;
    end
end

//-------------------AES decryption------------------------------------------
logic  [3:0]                    aes_dec_cnt;
logic  [3:0]                    aes_dec_cnt_new;
assign aes_dec_cnt_new = (aes_dec_cnt ==  NUM_ENCDEC_ROUNDS)  ? 4'h0  : aes_dec_cnt + 4'b1;
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_dec_cnt  <=  '0;
    end else begin
        if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_DECRYPT) begin
            aes_dec_cnt <=  aes_dec_cnt_new;
        end
    end
end

logic   [3:0]                   aes_dec_key_addr;
logic   [3:0]                   last_key_addr;
always_comb begin
    case (vexu2aes_length)
        SCR1_VCRYPT_256BIT  : last_key_addr = 4'he;
        SCR1_VCRYPT_128BIT  : last_key_addr = 4'ha;
    endcase
end

assign aes_dec_key_addr = last_key_addr - aes_dec_cnt;
assign AES_dec_finish   = (aes_dec_cnt ==  NUM_ENCDEC_ROUNDS);

logic [127 : 0]              aes_res_reg1;
logic [127 : 0]              aes_res_new1;
logic [127 : 0] invshiftrows_block, invaddkey_block;
logic [127 : 0] invaddkey_init_block, invaddkey_main_block, invaddkey_final_block;

always_comb begin
    aes_res_new1 = '0;
    invshiftrows_block    = InvShiftRows(invsbox2aes);
    invaddkey_block       = AddRoundKey(invshiftrows_block, key_mem_unified[aes_dec_key_addr]);
    invaddkey_init_block  = AddRoundKey(aes_op1_flat, key_mem_unified[aes_dec_key_addr]);
    invaddkey_main_block  = InvMixColumns(invaddkey_block);
    invaddkey_final_block  = invaddkey_block;
    if (vexu2aes_req & vexu2aes_func == SCR1_VCRYPT_FUNC_DECRYPT) begin
        case (aes_dec_cnt)
            4'b0  : aes_res_new1 = invaddkey_init_block;
            default : begin
                if (aes_dec_cnt != NUM_ENCDEC_ROUNDS) begin
                    aes_res_new1 = invaddkey_main_block;
                end else begin
                    aes_res_new1 = invaddkey_final_block;
                end
            end
        endcase
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aes_res_reg1 <=  '0;
    end else begin
        aes_res_reg1 <=  aes_res_new1;
    end
end

always_comb begin
    aes2sbox    = '0;
    aes2invsbox = '0;
    case (vexu2aes_func)
        SCR1_VCRYPT_FUNC_KEY_EXPAN  : aes2sbox  = {96'h0, w7};
        SCR1_VCRYPT_FUNC_ENCRYPT    : aes2sbox  = aes_res_reg0;
        SCR1_VCRYPT_FUNC_DECRYPT    : aes2invsbox = aes_res_reg1;
        default : begin   end
    endcase
end

always_comb begin
    case (vexu2aes_func)
        SCR1_VCRYPT_FUNC_KEY_EXPAN  : aes_res = '0;
        SCR1_VCRYPT_FUNC_ENCRYPT    : begin
            aes_res[0] = aes_res_new0[127:96];
            aes_res[1] = aes_res_new0[95:64];
            aes_res[2] = aes_res_new0[63:32];
            aes_res[3] = aes_res_new0[31:0];
        end
        SCR1_VCRYPT_FUNC_DECRYPT    : begin
            aes_res[0] = aes_res_new1[127:96];
            aes_res[1] = aes_res_new1[95:64];
            aes_res[2] = aes_res_new1[63:32];
            aes_res[3] = aes_res_new1[31:0];
        end
        default :                     aes_res = '0;
    endcase
end

assign aes_wreq = (AES_dec_finish | AES_enc_finish) ? 8'h0F : 8'h0;

endmodule
