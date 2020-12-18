#!/usr/bin/env python3

from migen import *
from migen.genlib.io import CRG
from migen.genlib.cdc import MultiReg

import nexys4ddr as tarjeta
#import c4e6e10 as tarjeta

from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.interconnect.csr import *

from litex.soc.cores import gpio
from module import rgbled
from module import sevensegment
from module import vgacontroller
from module import camara
from module import radar
from module import motor
from module import infra






# BaseSoC ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
	def __init__(self):
		platform = tarjeta.Platform()
		
		## add source verilog
		# camara.v
		platform.add_source("module/verilog/camara/camara.v")
		platform.add_source("module/verilog/camara/buffer_ram_dp.v")
		platform.add_source("module/verilog/camara/cam_read.v")
		platform.add_source("module/verilog/camara/procesamiento.v")
		platform.add_source("module/verilog/camara/VGA_driver.v")
		platform.add_source("module/verilog/camara/PLL/clk24_25_nexys4.v")
		platform.add_source("module/verilog/camara/PLL/clk24_25_nexys4_0.v")
		platform.add_source("module/verilog/camara/PLL/clk24_25_nexys4_clk_wiz.v")
		
		
		# Radar
		platform.add_source("module/verilog/radar/radar.v")
		platform.add_source("module/verilog/radar/servo.v")
		platform.add_source("module/verilog/radar/ultrasonido1.v")

		#motor 
		platform.add_source("module/verilog/motor/motor.v")
		
		#infrarojo
		platform.add_source("module/verilog/infrarojo/infra.v")
		platform.add_source("module/verilog/infrarojo/infrarojo.v")

		


		# SoC with CPU
		SoCCore.__init__(self, platform,
 			cpu_type="picorv32",
#			cpu_type="vexriscv",
			clk_freq=100e6,
			integrated_rom_size=0x8000,
			integrated_main_ram_size=10*1024)

		# Clock Reset Generation
		self.submodules.crg = CRG(platform.request("clk"), ~platform.request("cpu_reset"))

		# Leds
		SoCCore.add_csr(self,"leds")
		user_leds = Cat(*[platform.request("led", i) for i in range(10)])
		self.submodules.leds = gpio.GPIOOut(user_leds)
		
		# Switchs
		SoCCore.add_csr(self,"switchs")
		user_switchs = Cat(*[platform.request("sw", i) for i in range(8)])
		self.submodules.switchs = gpio.GPIOIn(user_switchs)
		
		# Buttons
		SoCCore.add_csr(self,"buttons")
		user_buttons = Cat(*[platform.request("btn%c" %c) for c in ['c','r','l']])
		self.submodules.buttons = gpio.GPIOIn(user_buttons)
		
		# 7segments Display
		SoCCore.add_csr(self,"display")
		display_segments = Cat(*[platform.request("display_segment", i) for i in range(8)])
		display_digits = Cat(*[platform.request("display_digit", i) for i in range(8)])
		self.submodules.display = sevensegment.SevenSegment(display_segments,display_digits)

		# RGB leds
		#SoCCore.add_csr(self,"ledRGB_1")
		#self.submodules.ledRGB_1 = rgbled.RGBLed(platform.request("ledRGB",1))
		
		#SoCCore.add_csr(self,"ledRGB_2")
		#self.submodules.ledRGB_2 = rgbled.RGBLed(platform.request("ledRGB",2))
		
				
		# VGA
		#SoCCore.add_csr(self,"vga_cntrl")
		vga_red = Cat(*[platform.request("vga_red", i) for i in range(4)])
		vga_green = Cat(*[platform.request("vga_green", i) for i in range(4)])
		vga_blue = Cat(*[platform.request("vga_blue", i) for i in range(4)]) # Se concatena
		vsync=platform.request("vsync")
		hsync=platform.request("hsync")
		#self.submodules.vga_cntrl = vgacontroller.VGAcontroller(hsync,vsync, vga_red, vga_green, vga_blue)
		 
		#camara
		SoCCore.add_csr(self,"camara_cntrl") # Incluir mapa de memoria
		SoCCore.add_interrupt(self,"camara_cntrl")
		cam_data_in = Cat(*[platform.request("cam_data_in", i) for i in range(8)])		
		self.submodules.camara_cntrl = camara.Camara(vsync,hsync,vga_red,vga_green,vga_blue,platform.request("cam_xclk"),platform.request("cam_pwdn"),platform.request("cam_pclk"),cam_data_in,platform.request("cam_vsync"),platform.request("cam_href"))
		
		# radar
		SoCCore.add_csr(self,"radar_cntrl") # Incluir mapa de memoria
		self.submodules.radar_cntrl = radar.Radar(platform.request("echo"),platform.request("done"),platform.request("trigger"),platform.request("PWM"))
        # motor
		SoCCore.add_csr(self,"motor_cntrl") # Incluir mapa de memoria
		self.submodules.motor_cntrl = motor.Motor(platform.request("A"),platform.request("B"),platform.request("C"),platform.request("D"),platform.request("A1"),platform.request("B1"),platform.request("C1"),platform.request("D1"))
				
        # infrarojo
		SoCCore.add_csr(self,"infra_cntrl") # Incluir mapa de memoria
		self.submodules.infra_cntrl = infra.Infra(platform.request("entrada"),platform.request("entrada1"),platform.request("entrada2"))


# Build --------------------------------------------------------------------------------------------
if __name__ == "__main__":
	builder = Builder(BaseSoC(),csr_csv="Soc_MemoryMap.csv")
	builder.build()

