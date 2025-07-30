module ADDR (  a, b,  sum );  

parameter width = 128;  

input [width-1 : 0] a,b;  
output [width : 0] sum;
 

assign sum  = a + b ;

endmodule
