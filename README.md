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

module buffer_ram_dp#(
	parameter AW = 15, // Cantidad de bits  de la direccion.
	parameter DW = 12, // Cantidad de Bits de los datos.
	parameter imageFILE = "/home/esteban/UNAL/GitHub/Digital_II/Camara_con_procesamiento/src/sources/images/circulo.men")
	(
	input clk_w,     		     // Frecuencia de toma de datos de cada pixel.
	input [AW-1: 0] addr_in, // Direccion del dato que entra.
	input [DW-1: 0] data_in, // Datos que entran a la memoria.
	input regwrite,		  	   // Habilita la escritura

  //VGA
	input clk_r, 				          // Reloj 25MHz VGA.
	input [AW-1: 0] addr_out, 		// Direccion del dato que se quiere leer.
	output reg [DW-1: 0] data_out,// Datos que si quiere leer.
	
	//Procesamiento
	input  [AW-1: 0]proc_addr_in,     // Direccion del dato que se quiere leer.
	output reg [DW-1: 0] proc_data_in	// Datos que si quiere leer.
	);
 
 Esta memoria originalmente era dual port (escribe y lee memoria al mismo tiempo), pero se adapto para ser trial port (3 puertos).

## Radar

Para el radar se utilizan dos dispositivos un servo motor(SG90)  y un ultrasonido( HC - SR04 )  el objetivo es usar el  servo motor con  tres grados de libertad( 0   ,90 gradas y 180 grados) para tomar la  distancia con el ultrasonido ( al frente, izquierda y derecha )   luego en software  se usara esa información  para la navegación.

![DIAGRAMA1](/docs/figure/motoryultra.png )
