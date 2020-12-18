`timescale 10ns/1ns
module UART_rs232_rx (Clk,Rst_n,RxEn,RxData,RxDone,Rx,Tick,NBits);		//Definimos el modulo UART_rs232_rx (Destinado para Recepción)

input Clk, Rst_n, RxEn,Rx,Tick;		//Definimos las entradas
input [3:0]NBits;		    //Bits recibidos

output RxDone;		    // Definimos las salidas
output [7:0]RxData;	    // Salida de 8 bits (Este es el dato recibido de 1 byte)


// Variables para maquina de estado
parameter  IDLE = 1'b0, READ = 1'b1; 	//Tenemos dos estados (READ y IDLE)
reg [1:0] State, Next;			//Creamos algunos registros auxilares
reg  read_enable = 1'b0;		//Variable habilitara o no el dato de lectura
reg  start_bit = 1'b1;			//Variable notificara la detección del bit de inicio (el primer flanco de bajada de RX)
reg  RxDone = 1'b0;		        //Variable notificara cuando el proceso de lectura este hecho
reg [4:0]Bit = 5'b00000;		//Variable usada para el ciclo de lectura bit a bit (como son 8 bits son 8 ciclos)
reg [3:0] counter = 4'b0000;          //Variable usada para contar los ciclos de tick hasta 16
reg [7:0] Read_data= 8'b00000000;      //Registro para almacenamos los bit de entrada de RX, antes de asignarlo por completo a la salida RX
reg [7:0] RxData;			//Registro para almacenar la salida RX


///////////////////////////////Maquina de Estados////////////////////////////////

////////////////////////////////////Reset////////////////////////////////////////////

	always @ (posedge Clk or negedge Rst_n)		// Instrución para resetear el sistema en cualquier ciclo de reloj
begin
	if (!Rst_n)	State <= IDLE;			//Si el reset esta en 0, nos vamos al estado inicial IDLE
else 		State <= Next;				//De lo contrario seguimos con el proximo estado
end

/* LLegamos a IDLE solo cuando RxDone es alto lo que significa que el proceso de lectura está terminado.
Además, mientras estamos en IDEL, llegamos al estado READ solo si la entrada Rx esta en bajo ( es decir se ha
detectado el bit de inicio) */
	
always @ (State or Rx or RxEn or RxDone)
begin
    case(State)	
	IDLE:	if(!Rx & RxEn)		Next = READ;	 
		else			Next = IDLE;
	READ:	if(RxDone)		Next = IDLE; 	 
		else			Next = READ;
	default 			Next = IDLE;
    endcase
end

/////////////////////////// Habilitar lectura o no///////////////////////////////

always @ (State or RxDone)
begin
    case (State)
	READ: begin
		read_enable <= 1'b1;			//Siempre que estemos en el estado READ, habilitamos el proceso de lectura para obtener los bits de RX con el Tick
	      end
	
	IDLE: begin
		read_enable <= 1'b0;			//Siempre que estemos en el estado IDLE, desahabilitamos el proceso de lectura para evitar obtener los bits de RX con el Tick
	      end
    endcase
end






///////////////////////////Leer el dato de entrada//////////////////////////////

/*
Cada vez que detectamos un pulso de Tick, aumentamos la variable counter.
- Cuando el contador es 8 (4'b1000) estamos en el medio del bit de inicio
- Cuando el contador es 16 (4'b1111) estamos en el medio de uno de los bits
- Almacenamos los datos cambiando el bit de entrada Rx al registro Read_data
usando esta línea de código: Read_data <= {Rx, Read_data [7: 1]};
*/
always @ (posedge Tick)

	begin
	if (read_enable)
	begin
	RxDone <= 1'b0;							// Establece el registro RxDone en bajo ya que el proceso aún continúa
	counter <= counter+1;						// Incrementa  counter en 1 con cada Tick detectado
	

	if ((counter == 4'b1000) & (start_bit))			  // Si el contador es 8, establecemos el bit de inicio en 0. 
	begin
	start_bit <= 1'b0;
	counter <= 4'b0000;
	end

	if ((counter == 4'b1111) & (!start_bit) & (Bit < NBits))	// Hacemos 8 ciclos y leemos los 8 bits
	begin
	Bit <= Bit+1;
	Read_data <= {Rx,Read_data[7:1]};
	counter <= 4'b0000;
	end
	
		if ((counter == 4'b1111) & (Bit == NBits)  & (Rx))	// Contamos hasta 16 una vez más y detectamos el bit de parada (la entrada Rx debe ser alta)
	begin
	Bit <= 4'b0000;
	RxDone <= 1'b1;
	counter <= 4'b0000;
	start_bit <= 1'b1;						// Restablecemos todos los valores para la siguiente entrada de datos y establecemos RxDone en alto
	end
	end
end



//////////////////////////////Asignamos la salida/////////////////////////////////


/* Finalmente, asignamos los valores del registro Read_data a la salida RxData y
ese será nuestro valor final recibido. */
	
always @ (posedge Clk)
begin

if (NBits == 4'b1000)
begin
RxData[7:0] <= Read_data[7:0];	
end

if (NBits == 4'b0111)
begin
RxData[7:0] <= {1'b0,Read_data[7:1]};	
end

if (NBits == 4'b0110)
begin
RxData[7:0] <= {1'b0,1'b0,Read_data[7:2]};	
end
end

//Fin del modulo RX
endmodule
