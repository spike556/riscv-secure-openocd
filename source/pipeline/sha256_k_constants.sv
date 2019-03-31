//======================================================================
//
// sha256_k_constants.v
// --------------------
// The table K with constants in the SHA-256 hash function.

module sha256_k_constants
(
    input  logic  [5 : 0]  addr,
    output logic  [31 : 0] K
);

  //----------------------------------------------------------------
  // addr_mux
  //----------------------------------------------------------------
always_comb begin
    case(addr)
        00: K = 32'h428a2f98;
        01: K = 32'h71374491;
        02: K = 32'hb5c0fbcf;
        03: K = 32'he9b5dba5;
        04: K = 32'h3956c25b;
        05: K = 32'h59f111f1;
        06: K = 32'h923f82a4;
        07: K = 32'hab1c5ed5;
        08: K = 32'hd807aa98;
        09: K = 32'h12835b01;
        10: K = 32'h243185be;
        11: K = 32'h550c7dc3;
        12: K = 32'h72be5d74;
        13: K = 32'h80deb1fe;
        14: K = 32'h9bdc06a7;
        15: K = 32'hc19bf174;
        16: K = 32'he49b69c1;
        17: K = 32'hefbe4786;
        18: K = 32'h0fc19dc6;
        19: K = 32'h240ca1cc;
        20: K = 32'h2de92c6f;
        21: K = 32'h4a7484aa;
        22: K = 32'h5cb0a9dc;
        23: K = 32'h76f988da;
        24: K = 32'h983e5152;
        25: K = 32'ha831c66d;
        26: K = 32'hb00327c8;
        27: K = 32'hbf597fc7;
        28: K = 32'hc6e00bf3;
        29: K = 32'hd5a79147;
        30: K = 32'h06ca6351;
        31: K = 32'h14292967;
        32: K = 32'h27b70a85;
        33: K = 32'h2e1b2138;
        34: K = 32'h4d2c6dfc;
        35: K = 32'h53380d13;
        36: K = 32'h650a7354;
        37: K = 32'h766a0abb;
        38: K = 32'h81c2c92e;
        39: K = 32'h92722c85;
        40: K = 32'ha2bfe8a1;
        41: K = 32'ha81a664b;
        42: K = 32'hc24b8b70;
        43: K = 32'hc76c51a3;
        44: K = 32'hd192e819;
        45: K = 32'hd6990624;
        46: K = 32'hf40e3585;
        47: K = 32'h106aa070;
        48: K = 32'h19a4c116;
        49: K = 32'h1e376c08;
        50: K = 32'h2748774c;
        51: K = 32'h34b0bcb5;
        52: K = 32'h391c0cb3;
        53: K = 32'h4ed8aa4a;
        54: K = 32'h5b9cca4f;
        55: K = 32'h682e6ff3;
        56: K = 32'h748f82ee;
        57: K = 32'h78a5636f;
        58: K = 32'h84c87814;
        59: K = 32'h8cc70208;
        60: K = 32'h90befffa;
        61: K = 32'ha4506ceb;
        62: K = 32'hbef9a3f7;
        63: K = 32'hc67178f2;
    endcase // case (addr)
end // block: addr_mux

endmodule // sha256_k_constants
