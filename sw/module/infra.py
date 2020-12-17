from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

# Modulo Principal
class Infra(Module,AutoCSR):
    def __init__(self,entrada,entrada1,entrada2):
            
     self.clk = ClockSignal() # Reloj global  

     self.entrada=entrada
     self.entrada1=entrada1
     self.entrada2=entrada2



     self.salida=CSRStatus()
     self.salida1=CSRStatus()
     self.salida2=CSRStatus()

    

     self.specials +=Instance("infra",
            i_clk= self.clk,
            i_entrada= self.entrada,
            i_entrada1= self.entrada1,
            i_entrada2= self.entrada2,

            o_salida=self.salida.status,
            o_salida1=self.salida1.status,
            o_salida2=self.salida2.status,
     
    )


