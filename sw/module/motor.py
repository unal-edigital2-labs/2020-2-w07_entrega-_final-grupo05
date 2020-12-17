from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

# Modulo Principal
class Motor(Module,AutoCSR):
    def __init__(self,A,B,C,D,A1,B1,C1,D1):

        self.clk = ClockSignal() # Reloj global   
        self.rst = ResetSignal() # Reset Global

        self.A=A
        self.B=B
        self.C=C
        self.D=D
        self.A1=A1
        self.B1=B1
        self.C1=C1
        self.D1=D1


 #Write
        self.direccion=CSRStorage(2)
        self.direccion2=CSRStorage(2)

        self.specials +=Instance("motor",
            i_clk= self.clk,
            i_rst= self.rst,
            
            o_A=self.A, 
            o_B=self.B,
            o_C=self.C,
            o_D=self.D,
            o_A1=self.A1, 
            o_B1=self.B1,
            o_C1=self.C1,
            o_D1=self.D1,


            
            #read
            
            #Write
            i_direccion=self.direccion.storage,
            i_direccion2=self.direccion2.storage,
        )
            





       