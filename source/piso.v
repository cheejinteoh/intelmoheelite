module PISO (
  din,
  clk,
  reset,
  load,
  dout
);

// INPUTS
input clk;
input reset;
input load;
input [128:0] din;

// OUTPUTS
output dout;

// REGS
reg dout;
reg [128:0] temp;

always @ (posedge clk or negedge reset) 
begin
 if (!reset) begin
   temp <= 0;
   dout <= 0;
 end else if (load) begin
   temp <= din;
 end else begin
   dout <= temp[128];
   temp <= {temp[127:0],1'b0};
 end
end

endmodule
