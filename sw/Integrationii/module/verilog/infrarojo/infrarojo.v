`timescale 10ns/1ns
module infrarojo(input clk, input entrada, output reg salida  ); 


reg h;

//assign  salida = 0; 
//C=1;// Se encarga de cambiar entre estados



always @(posedge clk) begin




if(entrada)
 begin 
   salida <= 1; 
 end
 else
 if(~entrada)
 begin 
 salida <= 0; 
 end
end 


 endmodule 