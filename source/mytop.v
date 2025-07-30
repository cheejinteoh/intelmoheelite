module MYTOP (clk, rst,loadsin, loadsout, loadm, sinA, sinB,   in1, in2, outA, outB );

//input PD;
input clk, rst, loadsin, loadsout, loadm, sinA, sinB ;
input [63:0] in1, in2 ;
wire [127:0] tmp_mult1, tmp_mult2, tmp_multA, tmp_multB ; 
wire [63:0] tmp_mult3, tmp_mult4, tmp_mult5, tmp_mult6;
wire [128:0] add_out, add2_out;
output  outA, outB;
reg [63:0] inA, inB, inC, inD ;

always @(posedge clk, negedge rst)
begin
 if (!rst)
 begin
 inA <= 0;
 inB <= 0;
 inC <= 0;
 inD <= 0;
end
 else 
  case (loadm)
   1'b1: 
     begin 
     inA <= in1; 
     inB <= in2;
     end
   1'b0:
     begin
     inC <= in1; 
     inD <= in2;
     end
   endcase
end


MULT  U0  (clk, rst, inA, inB, tmp_mult1 );  
MULT  U1  (clk, rst, inC, inD, tmp_mult2 );
ADDR  U2  (tmp_mult1, tmp_mult2, add_out);
PISO  U3  (add_out, clk, rst, loadsin, outA);

SIPO  U4  (clk, rst, loadsout, sinA, tmp_mult3);
SIPO  U5  (clk, rst, loadsout, sinB, tmp_mult4); 
MULT  U6  (clk, rst, tmp_mult3, tmp_mult4, tmp_multA); 
SIPO  U7  (clk, rst, loadsout, sinA, tmp_mult5);
SIPO  U8  (clk, rst, loadsout, sinB, tmp_mult6);
MULT  U9  (clk, rst, tmp_mult5, tmp_mult6, tmp_multB);
ADDR  UB  (tmp_multA, tmp_multB, add2_out);
PISO  UA  (add2_out, clk, rst, loadsout, outB);

endmodule


