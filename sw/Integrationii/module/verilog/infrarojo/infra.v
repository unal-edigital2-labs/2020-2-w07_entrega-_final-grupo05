`timescale 10ns/1ns
 module infra(  input clk,input entrada, output  salida,input entrada1, output  salida1, input entrada2, output  salida2   );
 
 
 infrarojo  infrarojo1(.clk(clk), .entrada(entrada),  .salida(salida) );
 infrarojo  infrarojo2(.clk(clk), .entrada(entrada1), .salida(salida1) );
 infrarojo  infrarojo3(.clk(clk), .entrada(entrada2), .salida(salida2));
 

 
 
 
 endmodule
