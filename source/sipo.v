module SIPO (
  clk,
  reset,
  data_valid,
  sin,
  pout
); 

input  clk;
input  reset;
input  sin;
input  data_valid;

output [63:0] pout; 
reg [63:0] tmp; 


always @(posedge clk or negedge reset) begin 
  if (!reset) begin
    tmp <= 0;
  end else begin 
    if (data_valid)
      tmp <= {tmp[62:0], sin}; 
  end
end 

assign pout = tmp;

endmodule
