`timescale 10ns/1ns
 module radar(  input clk, input echo, input [1:0] boton_cambiar_grados, output done, output trigger,
 output [15:0] distance, output PWM, input ultra);
 
 servo   servo( .clk (clk), .PWM(PWM), .boton_cambiar_grados(boton_cambiar_grados));
 ultrasonido1 ultrasonido2( .ultra(ultra), .clk(clk),  .echo(echo), .done(done), .trigger(trigger),.distance(distance));
 
 endmodule