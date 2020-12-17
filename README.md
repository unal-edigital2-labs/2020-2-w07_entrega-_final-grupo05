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

## Radar

Para el radar se utilizan dos dispositivos un servo motor(SG90)  y un ultrasonido( HC - SR04 )  el objetivo es usar el  servo motor con  tres grados de libertad( 0   ,90 gradas y 180 grados) para tomar la  distancia con el ultrasonido ( al frente, izquierda y derecha )   luego en software  se usara esa información  para la navegación.

![DIAGRAMA1](/docs/figure/motoryultra.png )

Se usara un top radar en donde se llamara los   módulos  servo.v   y al ultrasonido.v
``` verilog
`timescale 10ns/1ns
 module radar( input reset, input clk, input echo, input [1:0] boton_cambiar_grados, 
 output done, output trigger,output [15:0] distance, output PWM, input ultra);

 servo   servo( .clk (clk), .PWM(PWM), .boton_cambiar_grados(boton_cambiar_grados));
 
 ultrasonido1 ultrasonido2( .reset(reset), .clk(clk),  .echo(echo), .done(done), 
 .trigger(trigger),.distance(distance), .enc(ultra));
  endmodule  


```
##El modulo servo.v 
Este   dispositivo  funciona con tres  diferentes  pulsos (PWM)  a una velocidad definida por el DATA SHEET(1ms  para 0 grados ) ( 1.5ms para 90 grados )  y (2ms para 180 grados) separados  por un espacio 20ms


