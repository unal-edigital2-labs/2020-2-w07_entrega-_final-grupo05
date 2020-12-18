from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class Bluetooth(Module,AutoCSR):
    def __init__(self,
     self.clk=ClockSignal() 
     self.rst = ResetSignal() # Reset Global







    Clk                     ,
    	Rst_n                   ,   
   	Rx                      ,    
    	Tx                      ,
	RxData		