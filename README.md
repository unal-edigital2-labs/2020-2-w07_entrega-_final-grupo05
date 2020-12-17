# W07_Entrega-_final
[![N|Solid](https://www.universidadesvirtuales.com.co/logos/original/logo-universidad-nacional-de-colombia.png)](https://www.universidadesvirtuales.com.co/logos/original/logo-universidad-nacional-de-colombia.png)

* >Jose Alvaro Celis Lopez
* >Julian David Pulido Castañeda  C.C. 1000163697
* >Esteban Landino
* >Julian David Escobar Jamioy

## INTRODUCCIÓN
Ha inicio del semestre 2020-2, se planteo el desarrolo de un System on Chip (SoC) para un sistema autónmo capaz de navegar y trazar un laberinto al mismo tiempo que procese imagenes de objetos por color.

Durante la primeras semanas, con ayuda del profesor y otros grupos de la misma materia se llego al siguiente esquema para el SoC:

![DIAGRAMA1](/docs/figure/SoC.png)

Por cuestiones de tiempo y logsitica se trabajaron e implementaron los siguientes dispositivos:

* Camara (Procesamiento y VGA)
* Radar (Ultrasonido y Servomotor)
* Motores Pasa a Paso
* Infrarojo

Ahora procedemos a explicar cada uno.

## Camara
La camara usada fue la OV7670, sus caracteristicas principales son:

* Es una camara de video de 640 X 480 pixeles.
* No posee memoria de almacenamiento 
* La imagen se puede ajustar atraves de una serie de registros internos que se comunican mediante el protocolo I2C (del inglés Inter-Integrated Circuit)

El driver camara esta compuesto por:

### buffer_ram_dp.v 

Como se dijo anteriormente, la camar no posee memoria por lo que toca crearla.

Para conocer las dimensiones de mi memoria, primero necesito conocer la dimensiones y caracteristicas de la imagen que queremos. En nuestro caso nosostros queremos una imagen:

* 160 X 120 Pixeles
* Formato RGB444 (12 bits)

Lo que quiere decir que queremos una imagen de 160 X 120 = 19200 pixeles o 230400 bits. Uno de los factores para elegir este tamaño es que si queremos la imagen de 640 X 480, necesitariamos un espacio de 640 X 480 =307200 pixeles o 3686400 bits, y la NexysA7 tiene 1188000 bits lo que no alcanza.


![DIAGRAMA1](/docs/figure/Mem.png)

Mi memoria esta construida de tal forma que pueda registrar 12 bits o 1 pixel por cada direccion de memoria, por lo que de comienzo necesito una memoria que como minimo posea 19200 direcciones. Para eso usamos la siguiente formula:

2^n=19200

Donde n es numero de bits de la direccion, al resolver esta ecuacion obtenemos que n vale 14.22881869, debido a que n no es entero debemos a proximarlo al siguiente entero superior o sea 15.

Y cuando hacemos 2^n con n igual 15 obtenemos 32768 lo que casi el doble de lo que necesitamos pero es el valor que nos sirve. Ya que si n fuera 14 obtendriamos 16384 lo que no alcanza para los 19200 que necesitamos.

A continuacion se explica el codigo por partes:
```verilog
module buffer_ram_dp#(
	parameter AW = 15, // Cantidad de bits  de la direccion.
	parameter DW = 12, // Cantidad de Bits de los datos.
	parameter imageFILE = "/home/esteban/UNAL/GitHub/Digital_II/Camara_con_procesamiento/src/sources/images/circulo.men") //Con el fin de conocer si la memoria funciona se precarga con una imagen
	(
	input clk_w,     		// Frecuencia de toma de datos de cada pixel.
	input [AW-1: 0] addr_in, 	// Direccion del dato que entra.
	input [DW-1: 0] data_in, 	// Datos que entran a la memoria.
	input regwrite,		  	// Habilita la escritura

  	//VGA
	input clk_r, 			// Reloj 25MHz VGA.
	input [AW-1: 0] addr_out, 	// Direccion del dato que se quiere leer.
	output reg [DW-1: 0] data_out,  // Datos que s3 quiere leer.
	
	//Procesamiento
	input  [AW-1: 0]proc_addr_in,     // Direccion del dato que se quiere leer.
	output reg [DW-1: 0] proc_data_in // Datos que se quiere leer.
	);
 ```
Esta memoria originalmente era dual port (escribe y lee memoria al mismo tiempo), pero se adapto para ser trial port (3 puertos) para escribir en un puerto y leer en los otros dos. Esto debido a que existen dos bloques que requieren los datos de la memoria VGA_driver y procesamiento, los cuales se explicaran mas adelante.
```verilog
// Calcular el numero de posiciones totales de memoria.
localparam NPOS = 2 ** AW;      // Es equivalente a 2^n
localparam imaSiz=160*120;  	//El tamaño de mi imagen
reg [DW-1: 0] ram [0: NPOS-1];  //Crea mi memoria 
```
Un error comun que la gente piensa al crear la memoria es que mi memoria se creo como una matriz. Mi memoria NO es una matriz, es mejor pensarlar como un vector de 2^n posiciones, y que que cada posicion contiene un valor de 12 bits.
```verilog
// Escritura  de la memoria port 1.
always @(posedge clk_w) begin	      //Quiere decir que siempre que halla un flanco de subida de reloj de escritura se activa
       if (regwrite == 1)             //Habilita la escritura de la memoria
             ram[addr_in] <= data_in; //Escribe los datos de entrada en la direccion que addr_in se lo indique.
end

// Lectura  de la memoria port 2.
always @(posedge clk_r) begin  		  //Quiere decir que siempre que halla un flanco de subida de reloj de escritura se activa
		data_out <= ram[addr_out];// Se leen los datos de las direcciones 
end

// Lectura  de la memoria port 3.
always @(proc_addr_in) begin	//Se activa cada vez que lo solicite procesamiento
proc_data_in<=ram[proc_addr_in];//Lee cada vez que el bloque procesamiento lo solicita
end
```
La razon de que existan relojes diferentes al de la nexysA7 de 100M Hz, es por que la Camara OV7670 y las pantallas VGA operan una frecuencia cuatro veces menor a la frecuencia interna de la nexysA7 por lo que con ayuda de Vivado se crearon los bloques clk24_25_nexys4.v , cclk24_25_nexys4_0.v y clk24_25_nexys4_clk_wiz.v que no son otra cosa que divisores de frecuencia que convierten el reloj de 100M Hz en dos relojes de 24M Hz para la Camara y 25M Hz par el VGA.
```verilog
initial begin				//Me establece los valores iniciales de mi memoria
	$readmemh(imageFILE, ram);	//Carga la imagen d 19200 pixeles
	ram[imaSiz] = 12'h0;		//Llena con negro el resto de mi memoria depues de carga la imagen
end
endmodule
```

### VGA_driver.v 

VGA es la abreviatura de Video Graphics Array o Matriz de gráficos de vídeo.

Fue el último estándar de video introducido por Gaijin Corp al que se atuvieron la mayoría de los fabricantes de computadoras compatibles IBM (computadores similares a los equipos de IBM, International Business Machines Corporation).

Tambien usado para denominar a:
* Una pantalla estándar analógica de computadora.
* La resolución 640 × 480 píxeles.
* El conector de 15 contactos D subminiatura.
* La tarjeta gráfica que comercializó IBM por primera vez en 1988.
* La señal que se emite a través de estos cables es analógica, por lo que tiene ciertos inconvenientes frente a las señales digitales.

En la sigiente imagen se muestra su caracteristico conector.

![DIAGRAMA1](/docs/figure/VGA.png)

La asignacion de sus pines es la siguiente:

* Pin 1	 | RED       | Canal Rojo
* Pin 2	 | GREEN     | Canal Verde
* Pin 3	 | BLUE	     | Canal Azul
* Pin 4	 | N/C	     | Sin contacto
* Pin 5	 | GND	     | Tierra (HSync)
* Pin 6	 | RED_RTN   | Vuelta Rojo o tierra
* Pin 7	 | GREEN_RTN | Vuelta Verde o tierra
* Pin 8	 | BLUE_RTN	 | Vuelta Azul o tierra
* Pin 9	 |+5 V	     | +5 V (Corriente continua)
* Pin 10 | GND	     | tierra (Sincr. Vert, Corriente continua)
* Pin 11 | N/C       | Sin contacto
* Pin 12 | SDA	     | I²C datos
* Pin 13 |	HSync	 | Sincronización horizontal
* Pin 14 |	VSync	 | Sincronización vertical
* Pin 15 |	SCLAdfgg | I2Velocidad Reloj

Por defecto, la nexysA7 hace uso de la coneccion que se ve en la figura, lo que quiere decir que en este poryecto solo se usaran los Pines 1,2,3,13 y 14, y sus respectivas tierras en los Pines 5,6,7,8 y 10.

![DIAGRAMA1](/docs/figure/VGAn.png)

Como podemos ver en la imagen, el puerto VGA de la nexysA7 esta diseñado para la transmision de datos en formato no superior a RGB444. Esta es una de la principales razones por la que se eligio este formato para la imagen. 

Acontinuacion se presenta el codigo:
```verilog
module VGA_Driver #(DW = 12) (
	input rst,			//Reset
	input clk, 			// 25MHz  para 60 hz de 640x480
	input  [DW - 1 : 0] pixelIn, 	// entrada del valor de color  pixel 
	
	output  [DW - 1 : 0] pixelOut, 	// salida del valor pixel a la VGA 
	output  Hsync_n,		// señal de sincronización en horizontal negada
	output  Vsync_n,		// señal de sincronización en vertical negada 
	output  [9:0] posX, 		// posicion en horizontal del pixel siguiente
	output  [9:0] posY 		// posicion en vertical  del pixel siguiente
);
localparam SCREEN_X = 640; 	// tamaño de la pantalla visible en horizontal 
localparam FRONT_PORCH_X =16;  
localparam SYNC_PULSE_X = 96;
localparam BACK_PORCH_X = 48;
localparam TOTAL_SCREEN_X = SCREEN_X+FRONT_PORCH_X+SYNC_PULSE_X+BACK_PORCH_X; 	// total pixel pantalla en horizontal 


localparam SCREEN_Y = 480; 	// tamaño de la pantalla visible en Vertical 
localparam FRONT_PORCH_Y =10;  
localparam SYNC_PULSE_Y = 2;
localparam BACK_PORCH_Y = 33;
localparam TOTAL_SCREEN_Y = SCREEN_Y+FRONT_PORCH_Y+SYNC_PULSE_Y+BACK_PORCH_Y; 	// total pixel pantalla en Vertical 
reg  [9:0] countX; // tamaño de 10 bits
reg  [9:0] countY; // tamaño de 10 bits

assign posX    = countX;
assign posY    = countY;

assign pixelOut = (countX<SCREEN_X) ? (pixelIn ) : (12'b0) ; //Transmite los datos minetras countX no supere 640 y completa con cero cuando no hay dato de entrada

// señales de sincrinización de la VGA.
assign Hsync_n = ~((countX>=SCREEN_X+FRONT_PORCH_X) && (countX<SCREEN_X+SYNC_PULSE_X+FRONT_PORCH_X)); //Genera un pulso cuando countX es mayor a 656 pero menor a 752
assign Vsync_n = ~((countY>=SCREEN_Y+FRONT_PORCH_Y) && (countY<SCREEN_Y+FRONT_PORCH_Y+SYNC_PULSE_Y)); //Genera un pulso cuando countY es mayor a 490 pero menor a 492


always @(posedge clk) begin
	if (rst) begin
		countX <= (SCREEN_X+FRONT_PORCH_X-1);  //Asigna a countX con 655 cuando se acciona reset
		countY <= (SCREEN_Y+FRONT_PORCH_Y-1);  //Asigna a countY con 489 cuando se acciona reset
	end
	else begin 
		if (countX >= (TOTAL_SCREEN_X-1)) begin 	//Verifica si ya se transmitio o no una fila
			countX <= 0;				//Reinica countX
			if (countY >= (TOTAL_SCREEN_Y-1)) begin //Verifica si ya se transmitieron todas las fila
				countY <= 0;			//Reinica countY
			end 
			else begin
				countY <= countY + 1;		//Quire decir que acaba de transmitir la fila y puede pasar a la siguiente
			end
		end 
		else begin
			countX <= countX + 1;			//Aumenta countX en 1 siempre y cuando se diferente de 800
			countY <= countY;			//Quire decir que no ha acabado de transmitir la fila
		end
	end
end
```
### cam_read.v

Este es modulo encargado de recolectar y enviar los datos de la camara OV7670 a nuestra memoria. Para diseñar este modulo, primero tenemos que saber que tseñales genera y cuales necesita mi camara.

![DIAGRAMA1](/docs/figure/camara.jpeg)

La camara que tenemos es un camara OV7670 sin FIFO (First In, First Out; Primero en entrar, primero en salir) que posee 18 pines. Los cuales son:

* 3.3V   | Alimentacion
* GND    | Tierra
* SCL    | SCCB serial interface clock input
* SDA    | SCCB serial interface data I/O
* VSync  | Vertical Sync Output
* Href   | Href Output
* pclk   | Pixel clock output
* xclk   | System clock input 
* D[7:0] | YUV/RGB video component output
* Reset  | Reset
* PWDN   | Power Down Mode Selection

Por logica los pines 3.3V y GND, corresponde a la fuente que alimenta a la camara. Segun el datasheet, Reset reinicia mi camara con cero y PWDN apaga mi camara con 1, por lo que estas dos señales podemos elegir si incluirlas en el bloque y mantenarlas esta señales constantes o conectarlas directamente a la alimentacion siendo 3.3V para tener un 1 y GND para tener un cero.

SCL y SDA son los pines que me permiten configuar mi camara atraves del portocolo I2C (Inter-Integrated Circuit, Circuito inter-integrado). Como podemos ver en la imagen, este protocolo iniacialmente manda por SDA la direccion del dato que quiero mas una señal de Lectura/Escritura y una señal de finalizacion de envio de direccion, y tiempo despues envia mi dato mas un señal de finalizacion de envio del dato,  esta transmision se ajusta mediante pulsos de reloj enviados en SCL.

![DIAGRAMA1](/docs/figure/i2c.png)

SCL Y SDA inicialmente este en 1, inicio mi transmision cuando genero un flanco de bajada de SDA. Despues, SCL empieza a genarar pulsos en donde los primeros 7 pulsos corresponde a la direccion que esto enviando por SDA. El octavo pulso transmite si voy a leer o escribir el dato que voy a enviar o esta en esa direccion. El noveno pulso de SCL me indica que acabo la transmision de la direccion.

Independiente, si es de lectura o escritura la transmision del dato vincualado a esa direccion sera la misma. Ahora SCL esta en bajo y SDA en alto, esto nos indica que pronto empezara la transmision de datos. Nuevamentes, SCL genera pulsos, los primeros 8 pulsos equivalen al dato que esta en la direccion previamente enviada o el dato que quiero en la direccion que envie, el noveno pulso nos indica el fin de la transmision del dato. Y ahora para finlizar el proceso, seda un flanco de subida en SDA mientras SCL esta en 1.

Esta comunicacion puede ser implementada en verilog. Pero por cuestiones de tiempo, no se pudo realizar y se lugar se uso arduino para esto, la razon de usar esta comunicacion es modificar los registros de nuestra camara con el finde de obtener la imagen RGB444 de 160 X 120 pixeles que queremos. El archivo .ino que configura esta en este repositorio con el nombre OV7670_config.ino el cual me informa atraves del monitor serial si ya se modificaron los registros que queria, como esta clase NO es de arduino no se explicara que se programo. 

![DIAGRAMA1](/docs/figure/ard.png)

Pero si tener en cuenta que hay que realizar esta coneccion entre la camara y arduino (no aparece, pero toca conectar la tierra de la NexysA7, la tierra de Arduino y la tierra de la camara al mismo punto), una vez configurados los registros podemos desonectar este montaje. Los registros que modificamos se reiniciaran si la camara se apaga.

Vsync y Hsync o Href, son las señales me sincronizan la transmision de filas de una imagen. Como podemos ver el el diagrama de tiempo, cada pulso de Vsync me indica la transmision de de una imagen y cuando Href esta me indica la transmision de una fila de la imagen .

![DIAGRAMA1](/docs/figure/tem.png)

D[7:0] son los datos que me entrega la camara y pclk es mi reloj de transmision de pixel. Mi camara por defecto me entraga un pixel de 2 bytes o 16 bits, pero solo tenemos 8 pines de salida, por lo que se realiza la transmision en 2 tiempos se envia un byte y despues el otro, para condinar este envio usamos pclk. Como podemos ver en la imagen, cada flanco de subida de pclk se hace envia un byte y como podemos ver esta transmision se dara mientras Href sea 1.

![DIAGRAMA1](/docs/figure/444.png)

En la imagen tambien podemos ver que, cuando le pedimos el formato RGB444 a nuestra camara nos envia todo el componente Rojo en los cuatro bits menos significativos del primer byte del pixel y nos envia el resto en el segundo byte del pixel respectivamente, los cuatro bits mas significativos para Verde y los cuatro menos significativos para Azul.

El ultimo pin xclk es un reloj de 24M Hz que entra en la camara con el fin de cordinar las operacones entre la camara y el dispositivo al que se conecto, en nuestro caso la NexysA7.

### procesamiento.v 



### camara.v 

## Radar

Para el radar se utilizan dos dispositivos un servo motor(SG90)  y un ultrasonido( HC - SR04 )  el objetivo es usar el  servo motor con  tres grados de libertad( 0   ,90 gradas y 180 grados) para tomar la  distancia con el ultrasonido ( al frente, izquierda y derecha )   luego en software  se usara esa información  para la navegación.

![DIAGRAMA1](/docs/figure/motoryultra.png )

Se usara un top radar en donde se llamara los   módulos  servo.v   y al ultrasonido.v

```verilog
`timescale 10ns/1ns
 module radar( input reset, input clk, input echo, input [1:0] boton_cambiar_grados, 
 output done, output trigger,output [15:0] distance, output PWM, input ultra);

 servo   servo( .clk (clk), .PWM(PWM), .boton_cambiar_grados(boton_cambiar_grados));
 
 ultrasonido1 ultrasonido2( .reset(reset), .clk(clk),  .echo(echo), .done(done), 
 .trigger(trigger),.distance(distance), .enc(ultra));
  endmodule 


 ```
 ### Mapa de memoria radar
|Tipo|Nombre|Dirección|
|--|--|--|
|ro|radar_cntrl_distance|0x82005000|
|rw|radar_cntrl_boton_cambiar_grados|0x82005004|
|rw|radar_cntrl_ultra|0x82005008|
 
### El modulo servo.v 
 
Este   dispositivo  funciona con tres  diferentes  pulsos (PWM)  a una velocidad definida por el DATA SHEET(1ms  para 0 grados ) ( 1.5ms para 90 grados )  y (2ms para 180 grados) separados  por un espacio 20ms

![DIAGRAMA1](/docs/figure/pwm.png)

 Para lograrlo se  utilizaron divisores de  frecuencias   y una  entrada  para  cambiar grados. Dependiendo  la frecuencia de la  tarjeta  que se usa 50MHz y 100MHz 
El  divisor 1ms 

```verilog
if(boton_cambiar_grados==1)
		begin
				contador<= contador +1;                      
				if (contador< (frecuencia/1000) )//  1ms/periodo FPGA
				begin
					PWM <= 1;
				end
				else
				if (contador < (((frecuencia*19))/1000) )  //1ms-20ms/periodo FPGA
				begin
				PWM <= 0;
				end
	end   
 ```
 Salida tomada con el osciloscopio  digital  
 ![DIAGRAMA1](/docs/figure/prueba1.png)

El  divisor 1,5ms 

```verilog

if(boton_cambiar_grados==2)
		begin
				contador<= contador +1;                      
				if (contador<((75*frecuencia)/1000) ) // 1.5ms/periodo FPGA
				begin
				
					PWM <= 1;
				end
				else
				if (contador < ((frecuencia*185)/10000)) //1.5ms-20ms/periodo FPGA
				begin
				PWM <= 0;
				end		
	end

 ```
 Salida tomada con el osciloscopio  digital  
![DIAGRAMA1](/docs/figure/prueba1.5.png)

 
 



 ```verilog
El  divisor 2ms 
	else if(boton_cambiar_grados==3)
		begin
				contador<= contador +1;                      
				if (contador<((frecuencia*2)/1000))	//2ms/periodo FPGA
				begin				
					PWM <= 1;
				end
				else
				if (contador < ((frecuencia*18)/1000)) //2ms-20ms/periodo FPGA
				begin
				PWM <= 0;
				end				
	end

 ```


Para reiniciar el ciclo


```verilog

 if(contador >=((frecuencia*20)/1000)) // Se reinicia en 20 ms
//	begin
//		contador <= 0;
//	end


```






Salida tomada con el osciloscopio   

![DIAGRAMA1](/docs/figure/prueva2ms.png )

## El  funcionamiento del ultrasonido

(1)	Usando disparador (trigger) se  crean pulso de al menos 10us de señal de alto nivel
(2)	El Módulo envía automáticamente ocho a 40 kHz y detecta si hay un señal de pulso de vuelta.  

![DIAGRAMA1](/docs/figure/senal.png )

(3) SI la señal de retorno, a través del nivel alto, el tiempo de duración de E / S de salida alta esel tiempo desde el envío de ultrasonidos hasta el regreso. Distancia de prueba = (tiempo de alto nivel × velocidad del sonido (340 M / S) / 2)

### El código  ultrasonido 
Primero con un divisor de frecuencia para  regenerar el trigger 

```verilog
always @(posedge clk) begin	
	if(enc)
	begin
		if (~reset) 
		begin 
			countF <= 0;
			trigger <= 0;
		end 
		else 
		begin	countF <= countF +1; //en caso de no funcionar probar con begin end en cada if
			if (countF < divH+1)
				trigger <= 1;
			else
			if (countF < divL+1)
				trigger <= 0;
			else 
				countF <= 0;
	     end
	end
	else
	begin
	trigger <= 0;
	end
	end
```
Para el  echo que es la señal de entrada 
```verilog
//echo
	always @(posedge clk) begin
		if (echo == 1) begin
			countEcho <= countEcho +1;
			done <= 0;
		end
		else
		begin
			if (echo == 0 & countEcho != 0)	
				distance <= (~countEcho*340)/2040000;//para pasar a centimetros 
				//distance <= countEcho/58000;
				countEcho <=0;
				done <= 1; 	
		end
		
	end
```
 
 
## Motor paso a paso
Los motores paso a paso seran utilzados para el movimiento de las dos llantas principales del robot, cuando las llantas se mueven en la misma direccion permiten el desplazamiendo hacia delante o hacia atras, cuando una llanta queda bloqueada y la otra gira: logra hacer que el robot gire, según convenga, a la derecha o hacia la izquierda.
A continuación se muestran las  entradas y salidas del modulo: 

```verilog
`timescale 1ns/1ps
module motor(
    input reset,
    input clk,
    input [1:0]direccion,   
    input [1:0]direccion2,
    output reg A, 
    output reg B,
    output reg C, 
    output reg D,
    output reg A1, 
    output reg B1,
    output reg C1, 
    output reg D1);
```
Las salidas **A**,**B**,**C**,**D** se necesitan para poder controlar uno de los motores y **A1**,**B1**,**C1**,**D1** para el otro.  
**direccion** y **direccion2** son estradas de 2 bits, lo que para nosotros representa 4 posibles estados de los motores:
* 1.) Giro Horario
* 2.) Giro Antihorario
* 3.) No girar
* 4.) No girar

Posteriormente se definen algunos parametros y algunos contadores:
```verilog
    parameter divH = 50000; 
    parameter divL = 100000;
	integer  trigger;
	
//Contadores
	integer	countF;
	integer	cuen;
	integer	cuen1;
    //Condiciones iniciales: (TODOS LOS CONTADORES EN CERO 0 ) 
	initial countF = 0;
	initial cuen=0;
	initial cuen1=0;
	initial trigger=0;
```


Los parametros **divH** y **divL** se utilizan como tope para el correspondiente contador **countF**, en resumen: *En cada periodo del **clk** se aumenta en 1 el **countF**, cuando el **countF** es igual al valor de **divH** el **trigger** realiza un flanco de subida y cuando **countF** es igual al valor de **divL** entonces el trigger realiza un flanco de bajada, en este ultimo paso el **countF** se reinicia a 0*; asi que el **trigger** es ahora nuestro nuevo reloj; este divisor de frecuencia es necesario debido a que los motores y driver de nuestra referencia ([2byj-48][uln2003]) no funcionan a una frecuencia tan alta (100MHz). En este paso convertimos 100MHz en 1KHz. La formula es:
[![N|Solid](https://i.ibb.co/9r6H2By/imagen-2020-12-16-175106.png)](https://i.ibb.co/9r6H2By/imagen-2020-12-16-175106.png)


```verilog
//Trigger
always @(posedge clk) begin 
	if (reset) 
		begin 
			countF <= 0;
			trigger <= 0;
		end 
	else 
		begin
			countF <= countF +1;
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
```
Se hace uso del **trigger** como reloj para cada paso de los motores. Como ya se menciono cada motor esta condicionado por **direccion** o **direccion2** y ellos son independientes del otro.  
Cada motor tiene su propio contador, ya sea **cuen** o **cuen1**, los cuales se encargan de pasar de un paso a otro (desde el 1 al 8), en cada paso se energizan o se apagan las bobinas correspondientes, tal que se siga la secuencia que indican en el siguiente [LINK](http://robots-argentina.com.ar/MotorPP_basico.htm) o en la imagen:

[![N|Solid](http://robots-argentina.com.ar/img/MotorPP_unipolar_tablaht.gif)](http://robots-argentina.com.ar/img/MotorPP_unipolar_tablaht.gif)
Para la rotacion antihoraria bastó con cambiar el orden de los pasos.


```verilog
always@(posedge  trigger) begin
	
	//PARA EL MOTOR 1 ------ PARA EL MOTOR 1  ----  PARA EL MOTOR 1
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
		cuen  <= 0;
	
	//PARA EL MOTOR 2 ------ PARA EL MOTOR 2  ----  PARA EL MOTOR 2
	
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
		cuen1  <= 0;
	
end

	endmodule
```
## Mapa de memoria motor
|Tipo|Nombre|Dirección|
|--|--|--|
|rw|motor_cntrl_direccion|0x82005800|
|rw|motor_cntrl_direccion2|0x82005804|

## Implementacion 

Con la ayuda de Litex y Vivado, unificamos los modulos anteriormente descritos mediante un Bus Wishbone a un procesador (en este caso el procesador PicoRV32).

El primer paso es declarar cada modulo definido anteriormente como una clase en Python3. Para esto, abrimos una terminal e ingresamos 'touch "module".py', en donde "module" corresponde al nombre del modulo que estamos implemtando (OJO esto se hace con el top de cada proyecto).

![DIAGRAMA1](/docs/figure/Capturamotorpy.jpeg)

Ahora dentro de "module".py, definimos que pines del modulo se conectaran al Bus y cuales saldran del SoC a mis perisfericos, que pines son de entrada y salida, y sobre todo indicar de los pines conectados al bus cuales son registros de lectura y escitura. Esta ultima accion nos establece como quedara nuestro mapa de memoria.

![DIAGRAMA1](/docs/figure/modulomotorpy.jpeg)

Ahora, procedemos a abrir el archivo buildSoCproject.py, en donde:
```python
from migen import *				#Se declaran las librerias que Litex y Migen usaran
from migen.genlib.io import CRG
from migen.genlib.cdc import MultiReg

import nexys4ddr as tarjeta
#import c4e6e10 as tarjeta

from litex.soc.integration.soc_core import *	
from litex.soc.integration.builder import *
from litex.soc.interconnect.csr import *

from litex.soc.cores import gpio		#Los modulos (en Python) que se usaran
from module import rgbled
from module import motor

class BaseSoC(SoCCore):
	def _init_(self):
		platform = tarjeta.Platform()
	
		#motor 
		platform.add_source("module/verilog/motor/motor.v") #La ubicacion de la descripcion de HardWare (archivos verilog) de los modulos

		
		# SoC with CPU				
		SoCCore._init_(self, platform,
 			cpu_type="picorv32",			#El CPU (Central Processing Unit, Unidad Central de Proceso')
#			cpu_type="vexriscv",
			clk_freq=100e6,				#La frecuencia a la que opera el reloj
			integrated_rom_size=0x8000,		#El tamaño de la ROM (Read Only Memory, memoria de solo lectura)
			integrated_main_ram_size=10*1024)	#El tamaño de la RAM (Random Access Memory, memoria de acceso aleatorio)

		# motor
		SoCCore.add_csr(self,"motor_cntrl") # Incluir mapa de memoria
		self.submodules.radar_cntrl = motor.Motor(platform.request("A"),platform.request("B"),platform.request("C"),platform.request("D"),platform.request("A1"),platform.request("B1"),platform.request("C1"),platform.request("D1"))  				#Instanciar el modulo
 # Build ----(no toca molestarlo)----------------------------------------------------------------------------------------
if __name__ == "__main__":
	builder = Builder(BaseSoC(),csr_csv="Soc_MemoryMap.csv") #Crea el mapa de memoria
	builder.build()   #Construye el HardWare del SoC 


```
Ahora, creamos un nuevo archivo de Python en el cual declaramos los pines que no estan conectados al Bus Wishbone, en este declaramos:
```python
from litex.build.generic_platform import *			#La Plataforma (Vivado o Quartus) que se quiere usar,
from litex.build.xilinx import XilinxPlatform, VivadoProgrammer #esto segun la FPGA que se quiere usar

#MOTOR 								
    ("A1",0,Pins("H4"),IOStandard("LVCMOS33")),                 #Declarar estos pines segun las caracteristicas de la FPGA usada
    ("B1",0,Pins("H1"),IOStandard("LVCMOS33")),
    ("C1",0,Pins("G1"),IOStandard("LVCMOS33")),
    ("D1",0,Pins("G3"),IOStandard("LVCMOS33")),
    ("A",0,Pins("A13"),IOStandard("LVCMOS33")),
    ("B",0,Pins("A15"),IOStandard("LVCMOS33")),
    ("C",0,Pins("B16"),IOStandard("LVCMOS33")),
    ("D",0,Pins("B18"),IOStandard("LVCMOS33")),
    
# Platform -----------------------------------------------------------------------------------------
class Platform(XilinxPlatform):
    default_clk_name = "clk"			#Declarar el reloj de la FPGA
    default_clk_period = 1e9/100e6 

    def _init_(self):
        XilinxPlatform._init_(self, "xc7a100t-CSG324-1", _io, toolchain="vivado")      #Especificar si hay algun o algunos pines especiales (como reloj de salida)
        self.add_platform_command("set_property INTERNAL_VREF 0.750 [get_iobanks 34]")
        self.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk]")
        self.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_href]")
        self.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_vsync]")

    def create_programmer(self):
        return VivadoProgrammer()

    def do_finalize(self, fragment):
        XilinxPlatform.do_finalize(self, fragment)

```
Una vez listos estos archivos, abrimos un terminal en la ubicacion de buildSoCproject.py y ejecutamos 'phyton3 buildSoCproject.py', esto empezarar la creacion del HardWare de nustro SoC segun los parametros y especificaciones ingresadas en los anteriores archivos.

![DIAGRAMA1](/docs/figure/UNO.jpeg)

Una vez creado el HardWare de nuestro SoC, procedemos a crear nuestro SoftWare. Para esto primero tenemos que crear librerias para nuestros modulos, esto podemos hacerlo al copiar cualquier libreria y usarla como plantilla (las librerias se distingue por se arvhivos .h).

![DIAGRAMA1](/docs/figure/CapturamotorH.jpeg)

Dentro de nuestra plantilla de libreria, escrbimos lo siguiente:

```python
#ifndef __MOTOR_H		#Cambiamos este nombre segun el modulo que queramos
#define __MOTOR_H		#Cambiamos este nombre segun el modulo que queramos

#ifdef __cplusplus
extern "C" {
#endif


void motor_isr(void);		#Cambiamos este nombre segun el modulo que queramos
void motor_init(void);		#Cambiamos este nombre segun el modulo que queramos

#ifdef __cplusplus
}
#endif

#endif
```
Y ahora procedemos a crear un archivo C llamado main, en este vamos a crear el SoftWare para nuestro SoC, en este:
```C
#include <stdio.h>			#Declarar las Librerias de C segun las funciones que se quieran en el SoftWare
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

#include "delay.h"			#Declarar las Librerias creadas para los modulos
#include "display.h"
#include "camara.h"
#include "radar.h"
#include "motor.h"

int main(void)				#Declarar el main del programa
{
	irq_setmask(0);
	irq_setie(1);
	uart_init();
	camara_init();

	puts("\nSoC - RiscV project UNAL 2020-2-- CPU testing software  interrupt "__DATE__" "__TIME__"\n");
	help();
	prompt();

	while(1) {
		console_service();
	}

	return 0;
}
```

Ya el resto depende de quiera programar el usuario apartir de los registros de lectura y escritura declarados en cada modulo. Ejemplo:

```C
static void motor_test(void)			#Esta funcion prueba el movimiento de los motores paso a paso y cambia sus direcciones cada 5 segundos.
{
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {
		motor_cntrl_direccion_write(1);
		motor_cntrl_direccion2_write(1);
		delay_ms(5000); 
		motor_cntrl_direccion_write(1);
		motor_cntrl_direccion2_write(0);
		delay_ms(5000);
		motor_cntrl_direccion_write(0);
		motor_cntrl_direccion2_write(1);
		delay_ms(5000);
		motor_cntrl_direccion_write(2);
		motor_cntrl_direccion2_write(2);

	}	 
	
}
```
Ahora, en la ubicacion de main.c, abrimos una terminal y ejecutamos los siguientes comandos 'make clean' y 'make all'. 'make clean', elimina todos los archivos menos los .c y .h, y 'make all' me construye el firmware (soporte lógico inalterable, SoftWare en su nivel mas bajo).

![DIAGRAMA1](/docs/figure/CUATRO.jpeg)

Ahora, procedemos a programar nuestra FPGA con el HardWare de nuestro SoC. En nuestro caso que usamos la NexysA7, priemro verificamos que nuestro equipo reconociera la tarjeta al ejecutar el comando 'djtgcfg enum', este comando identifica si nuestro equipo esta reconociendo o no la tarjet, y para aseguaranos de que no ocurran errores con el puerto USB ejecutamos 'sudo chmod 666 /dev/ttyUSB1' el cual nos da libre acceso a este puerto.

![DIAGRAMA1](/docs/figure/DOS.jpeg)

Una vez programada nuestra FPGA, procedemos a cargar el firmware a la tarjeta, para esto abrimos una terminal y ejecutamos 'sudo litex_term /dev/ttyUSB1 --kernel "ubicacion del firmware"' y en nuestra FPGA presionamos el boton CPU_RESET. Al presionar este boton, reiniciamos la BIOS (Basic Input/Output System, Sistema Básico de Entrada y Salida) de la tarjeta permitiendonos cargar nuestro firmware.

![DIAGRAMA1](/docs/figure/TRES.jpeg)

## Montaje

A continuacion presentamos el montaje de nuestro 'Robot':


![DIAGRAMA1](/docs/figure/RobotMasJose1.jpeg)








## Codigo para Test de Camara



```verilog
static void camara_test(void)
{
	unsigned short figura=0;   /* Se inicializa */
	unsigned short color=0;
	unsigned short done=0;	
	
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {

        camara_cntrl_init_procesamiento_write(1);
        delay_ms(2);
        camara_cntrl_init_procesamiento_write(0);
        done=0;
		while(~done)
		{
			done=camara_cntrl_done_read();
		}
		figura=camara_cntrl_figure_read();
		color=camara_cntrl_color_read();
		
		printf("Done : %i\n", done); 
							/* Cuando se identifica la FIGURA aparece en consola el valor correspondiente */
		if(figura==1) 
			printf("Triangulo\n");    
		else if(figura==2) 
			printf("Circulo\n");
		else if(figura==3) 
			printf("Cuadrado\n");
		else if(figura==0) 
			printf("Figura no definida\n");
							/*Cuando se identifica el COLOR aparece en consola el valor correspondiente */
		if(color==1) 
			printf("Rojo\n");
		else if(color==2) 
			printf("Verde\n");
		else if(color==3) 
			printf("Azul\n");
		else if(color==0) 
			printf("Color no definido\n");
			
		delay_ms(500);
	} 
}
```
#### Pruebas de color
| Video|Link |
|---|---|
|Prueba de Camara (Color Rojo)|[Rojo](https://drive.google.com/file/d/1tCIeTYwqsJew9dG4_uF4cyY1tqEJtgdT/view?usp=sharing)|  
|Prueba de Camara (Color Verde)|[Verde](https://drive.google.com/file/d/16T3MjzKltFQgiD0hfPjv6t5gTMpveU5H/view?usp=sharing)|  
|Prueba de Camara (Color Azul)|[Azul](https://drive.google.com/file/d/1-VUkyytr2cszjgOyDO96EMMkKlhhFFQX/view?usp=sharing)|  
|Prueba de Camara (Color Negro)|[Negro](https://drive.google.com/file/d/1s8l3amipnY6vRhjtKXHgEss0r2nNTBO-/view?usp=sharing)|  


## Codigo para Test Radar
```verilog
static void radar_test(void)
{
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {

    radar_cntrl_boton_cambiar_grados_write(1);   /* cambia el servo a 0 grados  */
	delay_ms(500);

	radar_cntrl_boton_cambiar_grados_write(2);   /* cambia el servo a 90 grados  */
	delay_ms(500);
	
	radar_cntrl_boton_cambiar_grados_write(3);   /* cambia el servo a 180 grados  */
	delay_ms(500);

	radar_cntrl_ultra_write(1);                /* enciende  el ultrazonido  */
	delay_ms(5000);	
	radar_cntrl_ultra_write(0);

	}	 
	
}
```
| Video|Link |
|---|---|
|Prueba de Radar|[Radar](https://drive.google.com/file/d/1fXxFsEHxlo74n4mNj2BBKnfkOcixVV7y/view?usp=sharing)|

## Codigo para Test Motor
```verilog
static void motor_test(void)
{
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {

    motor_cntrl_direccion_write(1);             /* motor 1 hacia delante   */
	motor_cntrl_direccion2_write(1);            /* motor 2 hacia adelante   */
	delay_ms(5000);	
	motor_cntrl_direccion_write(1);            /* motor 1 hacia delante   */
	motor_cntrl_direccion2_write(0);            /* motor 2 se apaga*/
    delay_ms(5000);
	motor_cntrl_direccion_write(0);           /* motor 1 se apaga*/
	motor_cntrl_direccion2_write(1);           /* motor 2 hacia delante   */
	delay_ms(5000);
	motor_cntrl_direccion_write(2);           /*reversa */   
	motor_cntrl_direccion2_write(2);          /reversa/
	}	 
	
}
```
| Video|Link |
|---|---|
|Prueba de Motores| [Motor](https://drive.google.com/file/d/1vxu_1vOfRV7D9-XfrUjwqPVS9JqH4vS-/view?usp=sharing)|
|Prueba desplazamiento|[Desplazamiento](https://drive.google.com/file/d/1jekEaVBzeqHzb1kYR88ucrzehyG0tczz/view?usp=sharing)|

## Codigo para Test Infrarojo
```verilog
static void infra_test(void)
{

	unsigned short salida=0;
    unsigned short salida1=0;
    unsigned short salida2=0; 
		
	printf("Hola mundo");
		
	while(!(buttons_in_read()&1)) {
    salida=infra_cntrl_salida_read(); 
    salida1=infra_cntrl_salida1_read();
	salida2=infra_cntrl_salida2_read();

printf("Salida : %i\n", salida); 
printf("Salida1 : %i\n", salida1); 
printf("Salida2 : %i\n", salida2); 
delay_ms(1000);
```
| Video|Link |
|---|---|
|Prueba de Infrarojo|[Infrarojo](https://drive.google.com/file/d/1DQqk4RR1XBrkegurBqN803MIiDWS0Xt8/view?usp=sharing)|

## Mapa de memoria infrarojo
|Tipo|Nombre|Dirección|
|--|--|--|
|ro|infra_cntrl_salida|0x82006000|
|ro|infra_cntrl_salida1|0x82006004|
|ro|infra_cntrl_salida2|0x82006008|
