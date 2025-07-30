module MULT (clk, rst,  a, b, c );  

parameter inst_a_width = 64;  
parameter inst_b_width = 64;  

input [inst_a_width-1 : 0] a;  
input [inst_b_width-1 : 0] b;  
input clk;  
input rst;  
output [inst_a_width+inst_b_width-1 : 0] c;  
reg [inst_a_width+inst_b_width-1 : 0] c, p1, p2;
wire [inst_a_width+inst_b_width-1 : 0] prodab;


always @(posedge clk, negedge rst)
begin 
 if(!rst)
 begin
 p1 <= 0;
 p2 <= 0;
 c  <= 0;
 end
 else
 begin
 p1 <= prodab;
 p2 <= p1;
  c <= p2; 
 end
end

assign prodab = a * b;
endmodule
