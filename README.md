# W07_Entrega-_final
[![N|Solid](https://www.universidadesvirtuales.com.co/logos/original/logo-universidad-nacional-de-colombia.png)](https://www.universidadesvirtuales.com.co/logos/original/logo-universidad-nacional-de-colombia.png)

* >Jose Alvaro Celis Lopez
* >Julian David Pulido Castañeda
* >Esteban Landino
* >Julian Escobar

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

* Es una camara de video
* No posee memoria de almacenamiento 
* La imagen se puede ajustar atraves de una serie de registros internos que se comunican mediante el protocolo I2C (del inglés Inter-Integrated Circuit)

El driver camara esta compuesto por:

### buffer_ram_dp.v 

Como se dijo anteriormente, la camar no posee memoria por lo que toca crearla.

Para conocer las dimensiones de mi memoria, primero necesito conocer la dimensiones y caracteristicas de la imagen que queremos. En nuestro caso nosostros queremos una imagen:

* 160 X 120 Pixeles
* Formato RGB444 (12 bits)

Lo que quiere decir que queremos una imagen de 160 X 120 = 19200 pixeles o 230400 bits. 

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
 
![DIAGRAMA1](/docs/figure/prueba1.5.png)

 
 
