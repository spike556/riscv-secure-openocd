// sha 256

`include "scr1_riscv_isa_decoding.svh"

module sha
(
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    //  VEXU  -> SHA Interface
    input  logic                                vexu2sha_req,            // vexu request
    input  type_scr1_vcrypt_func_e              vexu2sha_func,           // init, hash
    output logic                                sha2vexu_rdy,
    input  type_scr1_vrf_e_v [7:0]              sha_op1,                // data low  part (rs1)
    input  type_scr1_vrf_e_v [7:0]              sha_op2,                // data high part (rs2)
    output type_scr1_vrf_e_v [7:0]              sha_res,
    output logic [7:0]                          sha_wreq,

    // SHA  -> ADDER Interface
    output  type_scr1_vrf_e_v [7:0]             sum_op1,
    output  type_scr1_vrf_e_v [7:0]             sum_op2,
    output  logic                               sum_sub,
    input   logic [7:0]      [31:0]             sum_res
);

// -----------------------SHA256 inline function---------------------------------
function logic [31:0]  SSigma_0  (
    input   logic [31:0]  in
);
    logic         [31:0]  out;
begin
    out = {in[6  : 0], in[31 :  7]} ^
          {in[17 : 0], in[31 : 18]} ^
          {3'b000, in[31 : 3]};
    return out;
end
endfunction : SSigma_0

function logic [31:0]  SSigma_1  (
    input   logic [31:0]  in
);
    logic         [31:0]  out;
begin
    out = {in[16 : 0], in[31 : 17]} ^
          {in[18 : 0], in[31 : 19]} ^
          {10'b0000000000, in[31 : 10]};
    return out;
end
endfunction : SSigma_1

function logic [31:0] LSigma_0  (
    input   logic [31:0]  in
);
    logic         [31:0]  out;
begin
    out = {in[1  : 0], in[31 :  2]} ^
          {in[12 : 0], in[31 : 13]} ^
          {in[21 : 0], in[31 : 22]};
    return out;
end
endfunction : LSigma_0

function logic [31:0] LSigma_1  (
    input   logic [31:0]  in
);
    logic         [31:0]  out;
begin
    out = {in[5  : 0], in[31 :  6]} ^
          {in[10 : 0], in[31 : 11]} ^
          {in[24 : 0], in[31 : 25]};
    return out;
end
endfunction : LSigma_1

function logic [31:0] Conditional  (
    input   logic [31:0]  e,
    input   logic [31:0]  f,
    input   logic [31:0]  g
);
    logic         [31:0]  out;
begin
    out = (e & f)  ^ ((~e) & g);      //  (e and f) xor ((not e) and g)
    return out;
end
endfunction : Conditional

function logic [31:0] Majority  (
    input   logic [31:0]  a,
    input   logic [31:0]  b,
    input   logic [31:0]  c
);
    logic         [31:0]  out;
begin
    out = (a & b)  ^ (a & c) ^ (b & c);
    return out;
end
endfunction : Majority
//---------------------------local parameter--------------------------------------
parameter SHA256_H0_0 = 32'h6a09e667;
parameter SHA256_H0_1 = 32'hbb67ae85;
parameter SHA256_H0_2 = 32'h3c6ef372;
parameter SHA256_H0_3 = 32'ha54ff53a;
parameter SHA256_H0_4 = 32'h510e527f;
parameter SHA256_H0_5 = 32'h9b05688c;
parameter SHA256_H0_6 = 32'h1f83d9ab;
parameter SHA256_H0_7 = 32'h5be0cd19;
//--------------------------SHA 256 main logic------------------------------------
// -----------------------------hash fsm------------------------------------------
typedef enum logic  {
    SHA_HASH_STAGE0,
    SHA_HASH_STAGE1
}   type_sha_hash_stage_e;
type_sha_hash_stage_e  sha_hash_stage;
logic [5:0]   sha_hash_cnt;
logic [5:0]   sha_hash_cnt_new;

always_comb begin
    case (vexu2sha_func)
        SCR1_VCRYPT_FUNC_HASH : sha2vexu_rdy =  (sha_hash_stage  ==  SHA_HASH_STAGE1);
        default : sha2vexu_rdy  = 1'b1;
    endcase
end
assign sha_hash_cnt_new = (sha_hash_stage == SHA_HASH_STAGE0) ?
                           sha_hash_cnt  + 6'b1  : '0;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sha_hash_cnt  <=  '0;
    end else begin
        if (vexu2sha_req & vexu2sha_func == SCR1_VCRYPT_FUNC_HASH) begin
            sha_hash_cnt  <=  sha_hash_cnt_new;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sha_hash_stage <=  SHA_HASH_STAGE0;
    end else begin
        case (sha_hash_stage)
            SHA_HASH_STAGE0  : begin
                if (sha_hash_cnt ==  6'd63)  begin
                    sha_hash_stage <=  SHA_HASH_STAGE1;
                end
            end
            SHA_HASH_STAGE1  : begin
                sha_hash_stage <=  SHA_HASH_STAGE0;
            end
        endcase
    end
end
//---------------message handle and hash funtion processs simultaneously----------
logic [15 : 0] [31 : 0] w_in;
logic [15 : 0] [31 : 0] w_mem;
logic                   w_write;
logic [15 : 0] [31 : 0] w_mem_new;
logic [31 : 0]          w;
logic [31 : 0]          w_new;

assign w_in = {sha_op2, sha_op1};
always_comb begin
    if (sha_hash_cnt < 6'd16) begin
        w = w_in[sha_hash_cnt];
    end else begin
        w = w_new;
    end
end

always_comb begin
    if (sha_hash_cnt == 6'd15) begin
        w_write = 1'b1;
        w_mem_new[0] = w_in[0];
        w_mem_new[1] = w_in[1];
        w_mem_new[2] = w_in[2];
        w_mem_new[3] = w_in[3];
        w_mem_new[4] = w_in[4];
        w_mem_new[5] = w_in[5];
        w_mem_new[6] = w_in[6];
        w_mem_new[7] = w_in[7];
        w_mem_new[8] = w_in[8];
        w_mem_new[9] = w_in[9];
        w_mem_new[10] = w_in[10];
        w_mem_new[11] = w_in[11];
        w_mem_new[12] = w_in[12];
        w_mem_new[13] = w_in[13];
        w_mem_new[14] = w_in[14];
        w_mem_new[15] = w_in[15];
    end
    else if (sha_hash_cnt > 6'd15) begin
        w_write = 1'b1;
        w_mem_new[0] = w_mem[01];
        w_mem_new[1] = w_mem[02];
        w_mem_new[2] = w_mem[03];
        w_mem_new[3] = w_mem[04];
        w_mem_new[4] = w_mem[05];
        w_mem_new[5] = w_mem[06];
        w_mem_new[6] = w_mem[07];
        w_mem_new[7] = w_mem[08];
        w_mem_new[8] = w_mem[09];
        w_mem_new[9] = w_mem[10];
        w_mem_new[10] = w_mem[11];
        w_mem_new[11] = w_mem[12];
        w_mem_new[12] = w_mem[13];
        w_mem_new[13] = w_mem[14];
        w_mem_new[14] = w_mem[15];
        w_mem_new[15] = w_new;
    end else begin
        w_mem_new[0] = '0;
        w_mem_new[1] = '0;
        w_mem_new[2] = '0;
        w_mem_new[3] = '0;
        w_mem_new[4] = '0;
        w_mem_new[5] = '0;
        w_mem_new[6] = '0;
        w_mem_new[7] = '0;
        w_mem_new[8] = '0;
        w_mem_new[9] = '0;
        w_mem_new[10] = '0;
        w_mem_new[11] = '0;
        w_mem_new[12] = '0;
        w_mem_new[13] = '0;
        w_mem_new[14] = '0;
        w_mem_new[15] = '0;
        w_write     = 1'b0;
    end
end

assign w_new = SSigma_0(w_mem[1]) + sum_res[7] + SSigma_1(w_mem[14]);

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        w_mem <=  '0;
    end else begin
        if (w_write) begin
            w_mem <=  w_mem_new;
        end
    end
end

//----------------------------------------------------------------
// Module instantiantions.
//----------------------------------------------------------------
logic  [31 : 0] k;
sha256_k_constants k_constants_inst(
    .addr(sha_hash_cnt),
    .K(k)
);
//---------------------------init operation-------------------------------
logic [7:0] [31:0] H_reg;
logic [7:0] [31:0] H_new;

always_comb begin
    case (vexu2sha_func)
        SCR1_VCRYPT_FUNC_INIT : begin
            H_new[0] = SHA256_H0_0;
            H_new[1] = SHA256_H0_1;
            H_new[2] = SHA256_H0_2;
            H_new[3] = SHA256_H0_3;
            H_new[4] = SHA256_H0_4;
            H_new[5] = SHA256_H0_5;
            H_new[6] = SHA256_H0_6;
            H_new[7] = SHA256_H0_7;
        end
        SCR1_VCRYPT_FUNC_HASH : H_new = sha_res;
        default : H_new = '0;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        H_reg <=  '0;
    end else begin
        if (vexu2sha_req) begin
            case (vexu2sha_func)
                SCR1_VCRYPT_FUNC_INIT : H_reg <=  H_new;
                SCR1_VCRYPT_FUNC_HASH : begin
                    if (sha_hash_stage  ==  SHA_HASH_STAGE1) begin
                        H_reg <=  H_new;
                    end
                end
                default : begin  end
            endcase
        end
    end
end
//---------------------------digest operation--------------------------------
logic [31:0] t1, t2;
logic  [7:0] [31:0]      sha_res_reg;
logic  [7:0] [31:0]      sha_res_new;

assign sum_sub = 1'b0;
always_comb begin
    t1 = 32'b0;
    t2 = 32'b0;
    sum_op1 = '0;
    sum_op2 = '0;
    case (sha_hash_stage)
        SHA_HASH_STAGE0 : begin
            sum_op1[0] = sha_res_reg[7];
            sum_op2[0] = LSigma_1(sha_res_reg[4]);
            sum_op1[1] = k;
            sum_op2[1] = w;
            sum_op1[2] = sum_res[0];
            sum_op2[2] = Conditional(sha_res_reg[4], sha_res_reg[5], sha_res_reg[6]);
            sum_op1[3] = sum_res[2];
            sum_op2[3] = sum_res[1];
            t1         = sum_res[3];                                  // t1

            sum_op1[4] = LSigma_0(sha_res_reg[0]);
            sum_op2[4] = Majority(sha_res_reg[0], sha_res_reg[1], sha_res_reg[2]);
            t2         = sum_res[4];                                 // t2

            sum_op1[5] = t1;
            sum_op2[5] = t2;
            sum_op1[6] = t1;
            sum_op2[6] = sha_res_reg[3];
            // for w_new generate
            sum_op1[7] = w_mem[0];
            sum_op2[7] = w_mem[9];
        end
        SHA_HASH_STAGE1 : begin
            for (int i = 0; i < 8; i++) begin
                sum_op1[i] = sha_res_reg[i];
                sum_op2[i] = H_reg[i];
            end
        end
    endcase
end

always_comb begin
    case (vexu2sha_func)
        SCR1_VCRYPT_FUNC_HASH : begin
            case (sha_hash_stage)
                SHA_HASH_STAGE0 : begin
                    sha_res_new[0] = sum_res[5];            // t1 + t2
                    sha_res_new[1] = sha_res_reg[0];
                    sha_res_new[2] = sha_res_reg[1];
                    sha_res_new[3] = sha_res_reg[2];
                    sha_res_new[4] = sum_res[6];           // t1 + d
                    sha_res_new[5] = sha_res_reg[4];
                    sha_res_new[6] = sha_res_reg[5];
                    sha_res_new[7] = sha_res_reg[6];
                end
                SHA_HASH_STAGE1 : begin
                    for (int i = 0; i < 8; i++) begin
                        sha_res_new[i] = sum_res[i];
                    end
                end
            endcase
        end
        default : sha_res_new = '0;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sha_res_reg <=  '0;
    end else begin
        if (vexu2sha_req) begin
            case (vexu2sha_func)
                SCR1_VCRYPT_FUNC_INIT : begin
                    sha_res_reg[0] <= SHA256_H0_0;
                    sha_res_reg[1] <= SHA256_H0_1;
                    sha_res_reg[2] <= SHA256_H0_2;
                    sha_res_reg[3] <= SHA256_H0_3;
                    sha_res_reg[4] <= SHA256_H0_4;
                    sha_res_reg[5] <= SHA256_H0_5;
                    sha_res_reg[6] <= SHA256_H0_6;
                    sha_res_reg[7] <= SHA256_H0_7;
                end
                SCR1_VCRYPT_FUNC_HASH : begin
                    sha_res_reg <=  sha_res_new;
                end
            endcase
        end
    end
end

assign sha_res = sha_res_new;
assign sha_wreq = (sha_hash_stage == SHA_HASH_STAGE1) ? 8'hff : '0;


endmodule
