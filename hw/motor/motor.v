
`timescale 1ns/1ps
module motor( input rst,input clk,
 output reg A, output reg B,output reg C, output reg D,
 output reg A1, output reg B1,output reg C1, output reg D1,
  input [1:0]direccion,   input [1:0]direccion2);



    parameter divH = 50000; 
    parameter divL = 100000;
	integer  trigger;
	
	//Contadores
	integer countF;
	integer  cuen;
	integer  cuen1;
	initial countF = 0;
	initial cuen=0;
	initial cuen1=0;
	initial   trigger=0;
 initial begin

A=1;
B=0;
C=1;
D=0;
end

//Trigger
	always @(posedge clk) begin 
		if (rst) 
		begin 
			countF <= 0;
			trigger <= 0;
		end 
		else 
		begin
			countF <= countF +1; //en caso de no funcionar probar con begin end en cada if
			if (countF < divH+1)
			begin
			
				trigger <= 1;
			end
			else
			if (countF < divL+1)
			begin
			
			trigger <= 0;
			end
			else 
			begin
				countF <= 0;
				end
		end
		
		
    

		
		
	end
	
	
	
	
always@(posedge  trigger) begin

//cuen  <= cuen +1;



if(direccion==1)
begin

cuen  <= cuen +1;
case(cuen)

1:  begin A=0;B=1;C=1;D=1; end 
	2:  begin A=0;B=0;C=1;D=1; end //inicial
	3:  begin A=1;B=0;C=1;D=1; end //inicial
	4:  begin A=1;B=0;C=0;D=1; end //inicial
	5:  begin A=1;B=1;C=0;D=1; end //inicial
	6:  begin A=1;B=1;C=0;D=0; end //inicial
	7:  begin A=1;B=1;C=1;D=0; end //inicial
	8:  begin A=0;B=1;C=1;D=0;cuen<=0; end //inicial
	
	endcase
end	
else 
if(direccion==2)	
begin
cuen  <= cuen +1;
	case(cuen)

	8:  begin A=0;B=1;C=1;D=1;cuen<=0; end 
	7:  begin A=0;B=0;C=1;D=1; end //inicial
	6:  begin A=1;B=0;C=1;D=1; end //inicial
	5:  begin A=1;B=0;C=0;D=1; end //inicial
	4:  begin A=1;B=1;C=0;D=1; end //inicial
	3:  begin A=1;B=1;C=0;D=0; end //inicial
	2:  begin A=1;B=1;C=1;D=0; end //inicial
	1:  begin A=0;B=1;C=1;D=0; end //inicial
	
	endcase
	
end
else
////if(direccion==0)	
//begin
cuen  <= 0;
	
	
//end





if(direccion2==2)
begin

cuen1  <= cuen1 +1;
case(cuen1)

1:  begin A1=0;B1=1;C1=1;D1=1; end 
	2:  begin A1=0;B1=0;C1=1;D1=1; end //inicial
	3:  begin A1=1;B1=0;C1=1;D1=1; end //inicial
	4:  begin A1=1;B1=0;C1=0;D1=1; end //inicial
	5:  begin A1=1;B1=1;C1=0;D1=1; end //inicial
	6:  begin A1=1;B1=1;C1=0;D1=0; end //inicial
	7:  begin A1=1;B1=1;C1=1;D1=0; end //inicial
	8:  begin A1=0;B1=1;C1=1;D1=0;cuen1<=0; end //inicial
	
	endcase
end	
else
if(direccion2==1)	
begin
cuen1  <= cuen1 +1;
	case(cuen1)

	8:  begin A1=0;B1=1;C1=1;D1=1;cuen1<=0; end 
	7:  begin A1=0;B1=0;C1=1;D1=1; end //inicial
	6:  begin A1=1;B1=0;C1=1;D1=1; end //inicial
	5:  begin A1=1;B1=0;C1=0;D1=1; end //inicial
	4:  begin A1=1;B1=1;C1=0;D1=1; end //inicial
	3:  begin A1=1;B1=1;C1=0;D1=0; end //inicial
	2:  begin A1=1;B1=1;C1=1;D1=0; end //inicial
	1:  begin A1=0;B1=1;C1=1;D1=0; end //inicial
	
	endcase
	
end 
else
//if(direccion2==0)	
//begin
cuen1  <= 0;
		
//end

		
	
		
end
	endmodule
	
	