`timescale 10ns/1ns
 module top(  input clk,input entrada, output reg salida,input entrada1, output reg salida1, input entrada2, output reg salida2   );
 
 
 infrarojo  infrarojo1(.clk(clk), .entrada(entrada),  .salida(salida) );
 infrarojo  infrarojo2(.clk(clk), .entrada(entrada1), .salida(salida1) );
 infrarojo  infrarojo3(.clk(clk), .entrada(entrada2), .salida(salida2));
 
 
 
 endmodule
