
module raw_bitu
(
  input  logic [255:0] [7:0]   order,
  input  logic [255:0] data_in,
  output logic [255:0] data_out
);

always_comb begin
    for (int i = 0; i < 256; i = i + 1) begin
        data_out[i] = data_in[order[i]];
    end
end

endmodule
